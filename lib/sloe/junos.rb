require 'net/netconf/jnpr'
require 'sloe/common'

module Sloe
  class Junos < Sloe::Common

    def initialize(args, &block)
        super( args, &block )
    end

    def cli(cmd_str, attrs = nil)
      self.rpc.command(cmd_str, attrs).text
    end
  end
end
