module Sloe
  class Ixia

    # Create Sloe::Ixia object. This assumes you have the Ixia Linux TCL library installed
    # 
    # @param host [String] IP or DNS name of the Linux TCL server
    # @param port [FixNum] port number to connect Ixia IxN controller on
    # @param version [String] version of the IxHal
    # @param ixncfg [String] path to IxN config file
    # @param traffic_duration [FixNum] duration that traffic should run for, in seconds
    # @param ixia_exe [String] path to shell script that executes TCL
    # @param clear_stats_after [FixNum] number of seconds to wait after configuring protocols before clearing stats
    # @return [Sloe::Ixia] object that can execute IxN config file
    def initialize(host: 'localhost', port: 8009, version: nil, ixncfg: nil, traffic_duration: 60, ixia_exe: '/root/ixos/bin/ixia_shell', clear_stats_after: 10)
      if ixncfg == nil
        fail ArgumentError, "missing mandatory IxNetwork script"
      end

      @host = host
      @port = port
      @ixncfg = ixncfg
      @traffic_duration = traffic_duration
      @ixia_exe = ixia_exe
      @buildtime = Time.now.to_i
      # base csv file name on IxN cfg file name
      @csv_file = File.basename(ixncfg).sub('.ixncfg','')
      @clear_stats_after = clear_stats_after

      self
    end

    # Run IxN file and return Ixia stats as a CSV object
    def run
      run_setup
      sleep @clear_stats_after
      clear_stats
      sleep @traffic_duration
      csv = run_stats_gather
      csv
    end

    # Load IxN file, start all protocols and then start traffic
    def run_setup
      setup_tcl = File.open("/var/tmp/setup-#{@buildtime}", 'w')
      setup_tcl.write setup
      setup_tcl.close
      system "#@ixia_exe /var/tmp/setup-#{@buildtime}"
      File.delete setup_tcl
    end

    # Clear all Ixia stats. This removes "invalid" drops observed
    def clear_stats
      clear_tcl = File.open("/var/tmp/clear-#{@buildtime}", 'w')
      clear_tcl.write clear_traffic_stats
      clear_tcl.close
      system "#{@ixia_exe} /var/tmp/clear-#{@buildtime}"
      File.delete clear_tcl
    end

    # Stop Ixia traffic flows and gather Ixia stats
    def run_stats_gather
      stats_tcl = File.open("/var/tmp/stats-#{@buildtime}", 'w')
      stats_tcl.write finish
      stats_tcl.close
      system "#@ixia_exe /var/tmp/stats-#{@buildtime}"
      File.delete stats_tcl
      ftp = Net::FTP.new(@host)
      ftp.login
      file = "#{@csv_file}.csv"
      Dir.chdir "#{$log_path}/ixia" do
        ftp.get "Reports/#{file}"
      end
      ftp.delete "Reports/#{file}"
      ftp.delete "Reports/#{file}.columns"
      ftp.close
      CSV.read("#{$log_path}/ixia/#{file}", headers: true)
    end

    # Just run protocols. Do not start traffic
    def run_protocols
      run_proto = File.open("/var/tmp/run-proto-#{@buildtime}", 'w')
      tcl = connect
      tcl << load_config
      tcl << start_protocols
      tcl << disconnect
      run_proto.write tcl
      run_proto.close
      system "#{@ixia_exe} /var/tmp/run-proto-#{@buildtime}"
      File.delete run_proto
    end

    private
    
    def setup
      tcl = connect 
      tcl << load_config 
      tcl << start_protocols 
      tcl << start_traffic 
      tcl << disconnect
      tcl
    end

    def clear_traffic_stats
      tcl = connect
      tcl << clear_ixia_traffic_stats
      tcl << disconnect
      tcl
    end

    def finish
      tcl = connect
      tcl << stop_traffic
      tcl << get_stats
      tcl << disconnect
      tcl
    end

    def connect
      code = <<-TCL.gsub(/^\s+\|/,'')
        |set VERSION [package require IxTclNetwork]
        |
        |ixNet connect #@host -port #@port -version $VERSION
      TCL
      code
    end

    def load_config
      code = <<-TCL.gsub(/^\s+\|/,'')
        |ixNet exec loadConfig [ixNet readFrom "#@ixncfg"]
        |set root [ixNet getRoot]
        |set vportList [ixNet getList $root vport]
        |after 120000
        |ixTclNet::CheckLinkState $vportList doneList
        |if {[llength $doneList]} {
        |    puts "Error:  links are not up on $doneList"
        |    return -1
        |}
      TCL
      code
    end

    def start_protocols
      code = <<-TCL.gsub(/^\s+\|/,'')
        |ixNet exec startAllProtocols
        |after 30000
      TCL
      code
    end

    def start_traffic
      code = <<-TCL.gsub(/^\s+\|/,'')
        |set root [ixNet getRoot]
        |ixNet exec apply $root/traffic
        |ixNet exec start $root/traffic
        |for {set timeOut 10} {$timeOut >= 0} {incr timeOut -1} {
        |  if {[ixNet getAttr $root/traffic -state] == "started"} {
        |    break
        |  }
        |  update idletasks
        |  after 1000
        |}
      TCL
      code
    end

    def clear_ixia_traffic_stats
      code = <<-TCL.gsub(/^\s+\|/,'')
        |ixNet exec clearStats
      TCL
      code
    end
    
    def stop_traffic
      code = <<-TCL.gsub(/^\s+\|/,'')
        |set root [ixNet getRoot]
        |ixNet exec stop $root/traffic
        |after 10000
      TCL
      code
    end

    def get_stats
      code = <<-TCL.gsub(/^\s+\|/,'')
        |set root [ixNet getRoot]
        |set stats $root/statistics
        |set csvWindowsPath "c:\\\\inetpub\\\\ftproot\\\\Reports"
        |ixNet setAttr $stats -enableCsvLogging "true"
        |ixNet setAttr $stats -csvFilePath $csvWindowsPath
        |ixNet setAttr $stats -pollInterval 3
        |ixNet commit
        |set li1 [list "Flow Statistics"]
        |set csvFileName "#{@csv_file}"
        |set opts [::ixTclNet::GetDefaultSnapshotSettings]
        |lset opts [lsearch $opts *Location*] [subst {Snapshot.View.Csv.Location: $csvWindowsPath}]
        |lset opts [lsearch $opts *GeneratingMode*] {Snapshot.View.Csv.GeneratingMode: kAppendCSVFile}
        |lset opts [lsearch $opts *Settings.Name*] [subst {Snapshot.Settings.Name: $csvFileName}]
        |lset opts [lsearch $opts *Contents*] {Snapshot.View.Contents: "allPages"}
        |lappend opts [subst {Snapshot.View.Csv.Name: $csvFileName}]
        |ixTclNet::TakeViewCSVSnapshot $li1 $opts
      TCL
      code
    end

    def clean_up
      code = <<-TCL.gsub(/^\s+\|/,'')
        |cleanUp
      TCL
      code
    end

    def disconnect
      code = <<-TCL.gsub(/^\s+\|/,'')
        |ixNet disconnect
      TCL
      code
    end
  end
end
