require 'net/scp'
require 'snmp'

module Sloe
  # Base class. Inherits from {http://rubydoc.info/gems/netconf/Netconf/SSH Netconf::SSH}
  class Common < Netconf::SSH

    # Provides access to the SNMP object
    attr_reader :snmp

    # Create Sloe::Common object.
    # Accepts arguments for {http://rubydoc.info/gems/netconf/Netconf/SSH:initialize Netconf::SSH#new} and {http://rubydoc.info/gems/snmp/SNMP/Manager:initialize SNMP::Manager#new}
    def initialize(args, &block)
      @snmp_args = {
        :host        => args[:target], 
        :mib_dir     => args[:mib_dir], 
        :mib_modules => args[:mib_modules]
      }
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
