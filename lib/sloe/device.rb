require 'net/netconf'
require 'sloe/common'

module Sloe
  # Class for working with generic Netconf
  # (i.e. a device that does not support vendor specific extension)
  class Device < Sloe::Common
    # Sloe::Device object for generic Netconf device
    def initialize(args, &block)
      # Stop netconf gem from defaulting to :Junos and thus
      # loading :Junos extensions
      args[:os_type] = :Netconf
      super(args, &block)
    end
  end
end
