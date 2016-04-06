require 'net/netconf/jnpr'
require 'sloe/common'
require 'fileutils'

module Sloe
  # Class that supports Junos specifc Netconf extensions
  class Junos < Sloe::Common
    # execute CLI commands over NETCONF transport
    # returns plain text, rather than XML, by default
    #
    # @param cmd_str [String] A valid Junos CLI command.
    # @param attrs [Hash] Supports same attributes as
    # {http://rubydoc.info/gems/netconf/Netconf/RPC/Junos:command Junos#command}
    # @return nil if command returns no text. Otherwise returns text
    # in format requested (default is plain text)
    def cli(cmd_str, attrs = { format: 'text' })
      reply = rpc.command(cmd_str, attrs)
      reply.respond_to?(:text) ? reply.text : reply
    end

    # Simplifies applying configuration to a Junos device.
    # Uses Junos NETCONF extensions to apply the configuration.
    # Returns to the previous committed config if any arror occurs
    #
    # @param config [String] Configuration to be applied the device
    # @param attrs [Hash] Takes same attributes as
    # {http://rubydoc.info/gems/netconf/Netconf/RPC/Junos:load_configuration Junos#load_configuration}
    def apply_configuration(config, attrs = { format: 'text' })
      rpc.lock_configuration
      rpc.load_configuration(config, attrs)
      rpc.commit_configuration
      rpc.unlock_configuration
    end
  end
end
