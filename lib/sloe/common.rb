require 'net/scp'
require 'snmp'

module Sloe
  class Common < Netconf::SSH

    attr_reader :snmp

    def initialize(args, &block)
      @snmp_args = {:host => args[:target], :mib_dir => args[:mib_dir], :mib_modules => args[:mib_modules]}
      @snmp = SNMP::Manager.new(@snmp_args)
      
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
