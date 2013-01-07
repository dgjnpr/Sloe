require 'sloe/version'
require 'net/netconf'
require 'snmp'


module Sloe
	class Device < Netconf::SSH

	  def initialize(args)
	    super(args)
	    self.open

	    @snmp_args = {:host => args[:target], :mib_dir => args[:mib_dir], :mib_modules => args[:mib_modules]}
      @manager = SNMP::Manager.new(@snmp_args)
	    
      self
	  end

	  def snmp_get(object)
	  	@manager.get_value(object)
	  end

	  def snmp_get_pdu(object)
	  	@manager.get(object)
	  end

	  def snmp_get_bulk(non_repeaters, max_repetitions, object_list)
	  	@manager.get_bulk(non_repeaters, max_repetitions, object_list)
	  end

	  def snmp_get_next(object_list)
	  	@manager.get_next(object_list)
	  end

		# need to work out how to pass a code block to walk,
		# or how to add SNMP::Manager methods directly to this object	
	  def snmp_walk(object_list, index_column = 0, &block)
	  	@manager.walk(object_list, index_column, &block)
	  end
	end
end
