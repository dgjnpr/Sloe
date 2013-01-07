require "sloe/version"
require 'net/juniper/netconf/device'
require 'net/juniper/netconf/netconf_session'
require 'net/juniper/netconf/xml'
require 'snmp'

module Sloe
	class Device < Netconf::Device
	  attr_accessor :host, :user
	  attr_writer :password

	  def initialize(host,user,password)
	    super(host, :username => user, :password => password)
	    self.host = host
	    self.user = user
	    self.password = password
      self.connect

      # load all local yaml-fied MIB files
      @jnx_mibs = Dir.glob("./mibs/JUNIPER-*.yaml").map { |f| File.basename(f, '.yaml')}
      @mib_files = ["SNMPv2-SMI", "SNMPv2-MIB", "IF-MIB", "IP-MIB", "TCP-MIB", "UDP-MIB"].concat(@jnx_mibs)
      @manager = SNMP::Manager.new(:host => host, :mib_dir => './mibs', :mib_modules => @mib_files)
	    
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
	  # def snmp_walk(object_list, index_column = 0)
	  # 	@manager.walk(object_list, index_column)
	  # end

	  # following methods were used during initial dev. Should be removed once production ready

	  def get_ifd(ifd_name)
	    @rpc = "<get-interface-information><interface-name>#{ifd_name}</interface-name></get-interface-information>"
	    self.execute_rpc(@rpc)
	  end

	  def ifd_cli_inOctets(ifd_name)
	    @ifd = self.get_ifd(ifd_name)
	    @ifd.xpath('//input-bps').text.to_i
	  end

	  def ifd_snmp_inOctets(ifd_name)
	    @ifd = self.get_ifd(ifd_name)
	    @ifIndex = @ifd.xpath('/interface-information/physical-interface/snmp-index').text

      @manager.get('ifInOctets.' + @ifIndex).varbind_list[0].value.to_i
    end
	end
end
