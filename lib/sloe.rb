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

      @manager = SNMP::Manager.new(:host => host)
	    self
	  end

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
	    @ifIndex = @ifd.xpath('//snmp-index').text

	    SNMP::Manager.open(:Host => self.host) do |manager|
	      manager.get('ifInOctets.' + @ifIndex).varbind_list[0].value.to_i
	    end
	  end
	end
end
