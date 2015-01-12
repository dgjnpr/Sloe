require 'net/scp'
require 'snmp'

module Sloe
  # Base class. Inherits from {http://rubydoc.info/gems/netconf/Netconf/SSH Netconf::SSH}
  class Common < Netconf::SSH

    # Provides access to the SNMP object
    attr_reader :snmp
    attr_accessor :logging

    # Create Sloe::Common object.
    # Accepts arguments for {http://rubydoc.info/gems/netconf/Netconf/SSH:initialize Netconf::SSH#new} and {http://rubydoc.info/gems/snmp/SNMP/Manager:initialize SNMP::Manager#new}
    def initialize(args, &block)
      @snmp_args = {
        :host        => args[:target], 
        :mib_dir     => args[:mib_dir], 
        :mib_modules => args[:mib_modules]
      }
      @snmp = SNMP::Manager.new(@snmp_args)

      # logging of RPCs is optional. If arguments are provided then
      # they must be needed/enabled. This also requires extending
      # Netconf::RPC::Executor.method_missing(), which is done below
      self.logging = args[:logging]
      
      if block_given?
        super( args, &block )
        return
      else
        super(args)
        self.open
        self
      end
    end
  end
end

# monkey patch to include logging of RPCs
module Netconf
  class Transport
    attr_accessor :logging

    def initialize( &block ) 
      
      @state = :NETCONF_CLOSED
      @os_type = @args[:os_type] || Netconf::DEFAULT_OS_TYPE
            
      @rpc = Netconf::RPC::Executor.new( self, @os_type, self.logging )
      @rpc_message_id = 1
      
      if block_given?
        open( &block = nil )      # do not pass this block to open()
        yield self
        close()
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
end
