require 'net/scp'
require 'snmp'

module Sloe
  # Inherits from {http://rubydoc.info/gems/netconf/Netconf/SSH Netconf::SSH}
  class Common < Netconf::SSH
    # Provides access to the SNMP object
    attr_accessor :logging, :target, :mib_dir, :mib_modules, :snmp_port
    attr_accessor :community

    # Create Sloe::Common object.
    # Accepts arguments for
    # {http://rubydoc.info/gems/netconf/Netconf/SSH:initialize Netconf::SSH#new}
    # {http://rubydoc.info/gems/snmp/SNMP/Manager:initialize SNMP::Manager#new}
    def initialize(args, &block)
      @target = args[:target]
      parse_args(args)
      # logging of RPCs is optional. If arguments are provided then
      # they must be needed/enabled. This also requires extending
      # Netconf::RPC::Executor.method_missing(), which is done below
      self.logging = args[:logging]

      block_given? ? super(args, &block) : super(args)
      open unless block_given?
    end

    def snmp
      @snmp = SNMP::Manager.new(snmp_args)
    end

    private

    def snmp_args
      {
        host:        target,
        mib_dir:     mib_dir,
        mib_modules: mib_modules,
        community:   community,
        port:        snmp_port
      }
    end

    def parse_args(args)
      @mib_dir     = args[:mib_dir]
      @mib_modules = args[:mib_modules]
      @community   = args[:community]
      @snmp_port   = args[:snmp_port]
    end
  end
end

# monkey patch to include logging of RPCs
module Netconf
  class Transport
    attr_accessor :logging

    def initialize(&block)
      @state = :NETCONF_CLOSED
      @os_type = @args[:os_type] || Netconf::DEFAULT_OS_TYPE

      @rpc = Netconf::RPC::Executor.new(self, @os_type, self.logging)
      @rpc_message_id = 1
      
      if block_given?
        open(&block = nil)      # do not pass this block to open()
        yield self
        close
      end
    end
  end
  module RPC
    class Executor

      def initialize( trans, os_type, logging )
        @trans = trans
        @logging = logging
        begin  
          extend Netconf::RPC::const_get( os_type )
        rescue NameError
          # no extensions available ...
        end
      end

      def method_missing( method, params = nil, attrs = nil )
        rpc = Netconf::RPC::Builder.send( method, params, attrs )
        if @logging
          log_attrs = attrs ? attrs : {}
          log_attrs[:format] = 'text'
          Dir.mkdir @logging[:path]
          File.open("#{@logging[:path]}/#{@logging[:file]}", "w") { |file| 
            file.write rpc
            file.write @trans.rpc_exec( Netconf::RPC::Builder.send( method, params, log_attrs ))
          }
        end
        @trans.rpc_exec( rpc )
      end
    end
  end
  class SSH
    def scp
      @scp ||= Net::SCP.start(@args[:target],
                              @args[:username],
                              password: @args[:password],
                              port: @args[:port] || 22)
    end
  end
end
