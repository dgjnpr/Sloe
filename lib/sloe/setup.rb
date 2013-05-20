require 'celluloid'
require 'net/netconf'

module Sloe
  class Setup
    include Celluloid

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

        @routers.push({
          :host    => @hostname,
          :session => Netconf::SSH.new( @login ),
          :state   => :INCOMPLETE
        })
      end
    end

    def setup
      @routers.each do |r|
        r.async._setup
      end
    end

    def complete
      @all_state = 0
      while @all_state < @routers.length do
        @all_state = 0
        @routers.each { |r| @all_state += 1 if r[:state] == :COMPLETE }
      end
      true
    end

    private
      def _setup
        @lab = File.read( "#{@location['template']}/lab/lab.conf" )
        @config = []
        @config.push({:config => @lab, :attrs => {:format => 'text', :action => 'merge'} })

        self[:session].open unless self[:session].state == :NETCONF_OPEN

        @specific = File.read( "#{@location['template']}/lab/#{self[:host]}.conf" )
        @config.unshift({
          :config => @specific, 
          :attrs => { :format => 'text', :action => 'override' }
        })
        _apply_config( @config )
        @config.shift

        if File.exist?( "#{@location['template']}/#{self[:host]}-re0.junos" )
          @ver = File.read( "#{@location['template']}/#{self[:host]}-re0.junos" ).chomp
          _upgrade_junos( @ver )
        end

        @tmpl = {
          :config => _generate_config( "#{@location['template']}/#{self[:host]}.yaml" ),
          :attrs  => { :format => 'text', :action => 'merge' }
        }
        _apply_config( @tmpl )
        self[:session].close
        self[:status] = :COMPLETE
      end

      def _apply_config( config )
        begin
          self[:session].rpc.lock_configuration
          config.each do |conf|
            self[:session].rpc.load_configuration( conf[:config], conf[:attrs] )
          end
          self[:session].rpc.commit_configuration
          self[:session].rpc.unlock_configuration
        rescue Netconf::LockError => e
          self[:session].rpc.unlock_configuration
          puts e.message
        rescue Netconf::EditError, Netconf::ValidateError, Netconf::CommitError, Netconf::RpcError => e
          self[:session].rpc.discard_changes
          self[:session].rpc.unlock_configuration
          puts e.message
        end
      end

      def _upgrade_junos( to_ver )
        from_ver = self[:session].rpc.get_system_information.xpath('//os-version').inner_text

        unless from_ver == to_ver
          @re = self[:session].rpc.get_route_engine_information.xpath('route-engine/mastership-state')
          args = {
            :package_name => "ftp://orion/#{to_ver}/jinstall-#{to_ver}-domestic-signed.tgz",
            :reboot => true,
            :no_copy => true,
            :unlink => true
          }

          # if dual RE perform upgrade on backup RE first
          if @re.size == 1
            self[:session].rpc.request_package_add( args )
          elsif @re[0].inner_text == "master"
            args[:re1] = true
            self[:session].rpc.request_package_add( args )
            args[:re0] = true
            args.delete(:re1)
            self[:session].rpc.request_package_add( args )
          else
            args[:re0] = true
            self[:session].rpc.request_package_add( args )
            args.delete(:re0)
            args[:re1] = true
            self[:session].rpc.request_package_add( args )
          end

          # close connection so we maintain same object while router reboots
          self[:session].close

          sleep 1800 # give the RE 20 mins to upgrade

          # re-establish connection once upgrade complete
          self[:session].open
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


