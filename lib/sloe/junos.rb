require 'net/netconf/jnpr'
require 'sloe/common'
require 'fileutils'

module Sloe
  # Class for working with Netconf device that supports Junos specifc Netconf extensions
  class Junos < Sloe::Common

    # Create Sloe::Junos object. It takes the same arguments as Sloe::Common
    #
    # @param args [Hash] key value pairs of arguments for object
    # @param block [Code] code block that will be executed once object created
    # @return [Sloe::Junos] object that interacts with a Junos device
    def initialize(args, &block)
        super( args, &block )
    end

    # execute CLI commands over NETCONF transport returns plain text, rather than XML, by default
    # 
    # @param cmd_str [String] A valid Junos CLI command.
    # @param attrs [Hash] Supports same attributes as {http://rubydoc.info/gems/netconf/Netconf/RPC/Junos:command Junos#command}
    # @return nil if command returns no text. Otherwise returns text in format requested (default is plain text)
    def cli(cmd_str, attrs = { :format => 'text' })
      attrs[:format] ||= 'text'
      reply = self.rpc.command(cmd_str, attrs)
      reply.respond_to?(:text) ? reply.text : reply
    end

    # Applies configuration to one or more Junos devices. This method is designed to make it easy to apply a list of configs to a list of Junos devices. Defaults are design for applying new configuration.
    # The :username and password arguments are used when connecting to the device to apply the configuration
    # The :glob argument is used to find a list of files containing config to apply. The default looks in ./configs/ for all files whose basename ends with "-apply".
    # The :match argument is used to find the hostname and configuration format of the config to apply. That file is applied to that host using the format gleaned from the filename suffix.
    # 
    # @param args [Hash] Hash of username, password, file glob and regex
    def setup( args = {
      :username => 'netconf', 
      :password => 'netconf', 
      :glob => "configs/*-apply.*", 
      :match => /(?<host>\w+)-apply\.(?<format>\w+)/} )
      _apply_configs( args )
    end

    # Applies configuration to one or more Junos devices. Defaults are designed for removing configuration.
    # @see #setup
    def clearup( args = {
      :username => 'netconf', 
      :password => 'netconf', 
      :glob => "configs/*-delete.*", 
      :match => /(?<host>\w+)-delete\.(?<format>\w+)/} )
      _apply_configs( args )      
    end

    # Simplifies applying configuration to a Junos device.
    # Uses Junos NETCONF extensions to apply the configuration. It also captures all config error conditions and ensures the config database is returned to the previous committed state.
    # 
    # @param config [String] Configuration to be applied the device
    # @param attrs [Hash] Takes same attributes as {http://rubydoc.info/gems/netconf/Netconf/RPC/Junos:load_configuration Junos#load_configuration}
    def apply_configuration( config, attrs = { :format => 'text' } )
      begin
        rpc.lock_configuration
        rpc.load_configuration( config, attrs )
        rpc.commit_configuration
        rpc.unlock_configuration
      rescue Netconf::LockError => e
        rpc.unlock_configuration
        puts e.message
      rescue Netconf::EditError => e
        rpc.discard_changes
        rpc.unlock_configuration
        puts e.message
      rescue Netconf::ValidateError => e
        rpc.discard_changes
        rpc.unlock_configuration
        puts e.message
      rescue Netconf::CommitError => e
        rpc.discard_changes
        rpc.unlock_configuration
        puts e.message
      rescue Netconf::RpcError => e
        rpc.discard_changes
        rpc.unlock_configuration
        puts e.message
      end
    end

    private

      def _apply_configs( args )
        raise Errno::ENOENT, "file glob matches no files" if Dir.glob( args[:glob] ).length < 1
        Dir.glob( args[:glob] ) do |file|
          param = args[:match].match( file )

          @login = {
            :target   => param[:host],
            :username => args[:username],
            :password => args[:password]
          }
          @dut = Sloe::Junos.new( @login )
          @config = File.read( file )
          apply_configuration( @config, :format => param[:format] )
          @dut.close
        end      
      end
  end
end
