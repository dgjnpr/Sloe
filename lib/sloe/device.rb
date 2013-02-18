require 'net/netconf'
require 'sloe/common'

module Sloe
  class Device < Sloe::Common

    def initialize(args, &block)

      # Stop netconf gem from defaulting to :Junos and thus 
      # not loading :Junos extensions
      args[:os_type] = :Netconf
      super( args, &block )
    end
  end
end
