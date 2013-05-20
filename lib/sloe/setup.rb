require 'celluloid'
require 'net/netconf'
require 'debugger'

module Sloe
  class Setup

    attr_reader :netconf, :hostname, :state

    def initialize( topology )
      raise Errno::ENOENT unless Dir.exists?( topology )
      @topology = topology
      @routers = []

      # refactor this, it's shite code but works
      if File.exist? './.gen_config.conf'
        @location = YAML.load_file( './.gen_config.conf' )
      elsif File.exist? "#{ENV['HOME']}/.gen_config.conf"
        @location = YAML.load_file( "#{ENV['HOME']}/.gen_config.conf" )
      elsif File.exist? '/etc/gen_config.conf'
        @location = YAML.load_file( '/etc/gen_config.conf' )
      else
        @location = {'template' => './templates'}
      end


      Dir.glob( "#{@topology}/*.yaml" ) do |yaml_file|
        @hostname = File.basename yaml_file, '.yaml'

        # establish netconf connection to router
        @login = {
          :target   => @hostname,
          :username => 'netconf',
          :password => 'netconf'
        }

        @netconf = Netconf::SSH.new( @login )
        @state   = :INCOMPLETE

        @routers.push( self )
      end
    end

    def setup
      # debugger
      @routers.each do |r|
        # r.async._setup
        r._setup
      end
      @state = :COMPLETE
    end

    def complete
      # @all_state = 0
      # while @all_state < @routers.length do
      #   @all_state = 0
      #   @routers.each { |r| @all_state += 1 if r.state == :COMPLETE }
      # end
      @state == :COMPLETE ? true : false
    end

    # private
      def _setup
        @lab = File.read( "#{@location['template']}/lab/lab.conf" )
        @config = []
        @config.push({:config => @lab, :attrs => {:format => 'text', :action => 'merge'} })

        self.netconf.open unless self.netconf.state == :NETCONF_OPEN

        @specific = File.read( "#{@location['template']}/lab/#{self.hostname}.conf" )
        @config.unshift({
          :config => @specific, 
          :attrs => { :format => 'text', :action => 'override' }
        })
        _apply_config( @config )
        @config.shift

        if File.exist?( "#{@location['template']}/#{self.hostname}-re0.junos" )
          @ver = File.read( "#{@location['template']}/#{self.hostname}-re0.junos" ).chomp
          _upgrade_junos( @ver )
        end

        @tmpl = {
          :config => _generate_config( "#{@location['template']}/#{self.hostname}.yaml" ),
          :attrs  => { :format => 'text', :action => 'merge' }
        }
        _apply_config( @tmpl )
        self.netconf.close
        @state = :COMPLETE
      end

      def _apply_config( config )
        begin
          self.netconf.rpc.lock_configuration
          config.each do |conf|
            self.netconf.rpc.load_configuration( conf[:config], conf[:attrs] )
          end
          self.netconf.rpc.commit_configuration
          self.netconf.rpc.unlock_configuration
        rescue Netconf::LockError => e
          self.netconf.rpc.unlock_configuration
          puts e.message
        rescue Netconf::EditError, Netconf::ValidateError, Netconf::CommitError, Netconf::RpcError => e
          self.netconf.rpc.discard_changes
          self.netconf.rpc.unlock_configuration
          puts e.message
        end
      end

      def _upgrade_junos( to_ver )
        from_ver = self.netconf.rpc.get_system_information.xpath('//os-version').inner_text

        unless from_ver == to_ver
          @re = self.netconf.rpc.get_route_engine_information.xpath('route-engine/mastership-state')
          args = {
            :package_name => "ftp://orion/#{to_ver}/jinstall-#{to_ver}-domestic-signed.tgz",
            :reboot => true,
            :no_copy => true,
            :unlink => true
          }

          # if dual RE perform upgrade on backup RE first
          if @re.size == 1
            self.netconf.rpc.request_package_add( args )
          elsif @re[0].inner_text == "master"
            args[:re1] = true
            self.netconf.rpc.request_package_add( args )
            args[:re0] = true
            args.delete(:re1)
            self.netconf.rpc.request_package_add( args )
          else
            args[:re0] = true
            self.netconf.rpc.request_package_add( args )
            args.delete(:re0)
            args[:re1] = true
            self.netconf.rpc.request_package_add( args )
          end

          # close connection so we maintain same object while router reboots
          self.netconf.close

          sleep 1800 # give the RE 20 mins to upgrade

          # re-establish connection once upgrade complete
          self.netconf.open
        end
      end

      def _generate_config( yaml )
        @params = YAML.load_file( yaml )
        @erb = ERB.new( File.read( "#{@topology_location['template']}/#{@params['template']}" ) )
        c = OpenStruct.new( yaml )

        @erb.result( c.send( :binding ) )
      end
  end
end


