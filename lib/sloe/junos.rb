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
    def initialize( args, &block )
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
  end
end
