require 'celluloid'
require 'net/netconf/jnpr'
require 'ostruct'
require 'debugger'

module Sloe
  class Setup

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
        @junos = Dir.glob( "#{@topology}/#{@hostname}*.junos" )

        self.setup( yaml_file, @junos )
      end
    end

    def setup( yaml, junos )
      @login = {
        :target   => @hostname,
        :username => 'netconf',
        :password => 'netconf'
      }

      @netconf = Netconf::SSH.new( @login )

      @lab = File.read( "#{@location['template']}/lab/lab.conf" )
      @config = []
      @config.push({:config => @lab, :attrs => {:format => 'text', :action => 'merge'} })

      @netconf.open unless @netconf.state == :NETCONF_OPEN

      @specific = File.read( "#{@location['template']}/lab/#{@hostname}.conf" )
      @config.unshift({
        :config => @specific, 
        :attrs => { :format => 'text', :action => 'override' }
      })
      _apply_config( @config )
      @config.shift
      @config.shift

      junos.each do |file|
        @ver = File.read( file )
        _upgrade_junos( @ver )
      end

      @config.push ({
        :config => _generate_config( yaml ),
        :attrs  => { :format => 'text', :action => 'merge' }
      })
      _apply_config( @config )
      @netconf.close

    end

    # private
      def _apply_config( config )
        begin
          @netconf.rpc.lock_configuration
          config.each do |conf|
            @netconf.rpc.load_configuration( conf[:config], conf[:attrs] )
          end
          @netconf.rpc.commit_configuration
          @netconf.rpc.unlock_configuration
        rescue Netconf::LockError => e
          @netconf.rpc.unlock_configuration
          puts e.message
        rescue Netconf::EditError, Netconf::ValidateError, Netconf::CommitError, Netconf::RpcError => e
          @netconf.rpc.discard_changes
          @netconf.rpc.unlock_configuration
          puts e.message
        end
      end

      def _upgrade_junos( to_ver )
        from_ver = @netconf.rpc.get_system_information.xpath('//os-version').inner_text

        unless from_ver == to_ver
          @re = @netconf.rpc.get_route_engine_information.xpath('route-engine/mastership-state')
          args = {
            :package_name => "ftp://orion/#{to_ver}/jinstall-#{to_ver}-domestic-signed.tgz",
            :reboot => true,
            :no_copy => true,
            :unlink => true
          }

          # if dual RE perform upgrade on backup RE first
          if @re.size == 1
            @netconf.rpc.request_package_add( args )
          elsif @re[0].inner_text == "master"
            args[:re1] = true
            @netconf.rpc.request_package_add( args )
            args[:re0] = true
            args.delete(:re1)
            @netconf.rpc.request_package_add( args )
          else
            args[:re0] = true
            @netconf.rpc.request_package_add( args )
            args.delete(:re0)
            args[:re1] = true
            @netconf.rpc.request_package_add( args )
          end

          # close connection so we maintain same object while router reboots
          @netconf.close

          sleep 1800 # give the RE 20 mins to upgrade

          # re-establish connection once upgrade complete
          @netconf.open
        end
      end

      def _generate_config( yaml )
        debugger
        @config = ''
        @params = YAML.load_file( yaml )
        @params.each do |tmpl|
          raise Errno::ENOENT unless File.exists?( "#{@location['template']}/#{tmpl['template']}" )
          @erb = ERB.new( File.read( "#{@location['template']}/#{tmpl['template']}" ) )
          c = OpenStruct.new( yaml )
          @config << @erb.result( c.send( :binding ) )
        end
        @config
      end
  end
end


