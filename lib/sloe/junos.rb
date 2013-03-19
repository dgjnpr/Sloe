require 'net/netconf/jnpr'
require 'sloe/common'

module Sloe
  class Junos < Sloe::Common

    def initialize(args, &block)
        super( args, &block )
    end

    def cli(cmd_str, attrs = { :format => 'text' })
      attrs[:format] ||= 'text'
      reply = self.rpc.command(cmd_str, attrs)
      reply.respond_to?(:text) ? reply.text : reply
    end
  end
end
