require 'celluloid'
require 'net/netconf/jnpr'
require 'ostruct'
require 'debugger'

module Sloe
  class Setup
    include Celluloid

    def initialize( topology, attrs = {:format => 'text', :action => 'merge'} )
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

        # @routers is an array of celluloid futures
        @routers.push self.future.setup( yaml_file, attrs, @junos )
      end
    end

    def setup( yaml, attrs, junos )
      @login = {
        :target   => @hostname,
        :username => 'netconf',
        :password => 'netconf'
      }

      @netconf = Netconf::SSH.new( @login ).open

      junos.each { |file| _upgrade_junos( file ) }

      @config = {
        :config => _generate_config( yaml ),
        :attrs  => attrs
      }
      _apply_config( @config )
      @netconf.close

      # return true to say we're done
      true
    end

    def complete?
      @state = false
      @routers.each do |complete|
        @state = complete.value == true ? true : false
        last if @state == false
      end
      @state
    end

    # private
      def _apply_config( config )
        begin
          @netconf.rpc.lock_configuration
          @netconf.rpc.load_configuration( config[:config], config[:attrs] )
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

      def _upgrade_junos( file )
        # debugger
        @upgrade_response = ''
        # extract image path from file, removing /var/junos/ from path
        @image_path = File.read( file ).sub!( '/var/junos/', '' ).chomp!

        @to_ver   = @image_path.match( '[^\/]+' )
        @from_ver = @netconf.rpc.get_system_information.xpath('//os-version').inner_text

        unless @from_ver == @to_ver.to_s
          @re = @netconf.rpc.get_route_engine_information.xpath('route-engine/mastership-state')
          args = {
            :package_name => "ftp://orion/#{@image_path}",
            :reboot => true,
            :no_copy => true,
            :unlink => true
          }

          # if dual RE perform upgrade on backup RE first
          if @re.size == 1
            @netconf.rpc.request_package_add( args )
          elsif @re[0].inner_text == "master"
            args[:re1] = true
            @upgrade_response = @netconf.rpc.request_package_add( args )
            raise UpgradeError if @upgrade_response.match( 'Warning' )
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
        @config = ''
        @params = YAML.load_file( yaml )
        @params.each do |tmpl|
          raise Errno::ENOENT unless File.exists?( "#{@location['template']}/#{tmpl['template']}" )
          @erb = ERB.new( File.read( "#{@location['template']}/#{tmpl['template']}" ) )
          c = OpenStruct.new( tmpl )
          @config << @erb.result( c.send( :binding ) )
        end
        @config
      end
  end
end


