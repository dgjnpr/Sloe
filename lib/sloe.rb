require 'sloe/version'
require 'net/netconf'
require 'snmp'


module Sloe
	class Device < Netconf::SSH

		attr_reader :snmp

	  def initialize(args)
	    super(args)
	    self.open

	    @snmp_args = {:host => args[:target], :mib_dir => args[:mib_dir], :mib_modules => args[:mib_modules]}
      @snmp = SNMP::Manager.new(@snmp_args)
	    
      self
	  end
	end
end
