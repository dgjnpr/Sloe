require 'net/netconf'
require 'sloe/common'

module Sloe
  class Device < Sloe::Common

    # attr_reader :snmp

    def initialize(args, &block)
      # @snmp_args = {:host => args[:target], :mib_dir => args[:mib_dir], :mib_modules => args[:mib_modules]}
      # @snmp = SNMP::Manager.new(@snmp_args)
      
      # if block_given?
        super( args, &block )
        # return
      # else
        # super(args)
        # self.open
        # self
      # end
    end
  end
end
