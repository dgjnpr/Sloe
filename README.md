# Sloe

Sloe uses NETCONF and/or SNMP to gather data regarding a network device. Designed to help with automated testing this gem can also be used with things like Ruby on Rails

## Installation

Add this line to your application's Gemfile:

    gem 'sloe'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sloe

## Usage

This gem augments the functionality of Netconf::SSH, Net::SCP and SNMP gems. Please refer to those gem's documentation or detailed instruction on how to use this gem.

All Netconf methods are accessed via the rpc() method. All Net::SCP methods are access via the scp() method. All SNMP methods are accessed via the snmp() method. For example:

    require 'sloe'

    # create options hash
    options = {:target => 'remotehost', :username => 'foo', :password => 'bar'}

    Sloe::Device.new(options) { |device|

      # call a Netconf RPC and display some of output
      inventory = device.rpc.get_chassis_inventory
      puts "Chassis: " + inventory.xpath('chassis/description').text

      # display SNMP data
      puts device.snmp.get_value('sysDescr.0')
    } 

An alternate way to use this module is:

    require 'sloe'

    # create options hash
    options = {:target => 'remotehost', :username => 'foo', :password => 'bar'}

    device = Sloe::Device.new(options)

    # call a Netconf RPC and display some of output
    inventory = device.rpc.get_chassis_inventory
    puts "Chassis: " + inventory.xpath('chassis/description').text

    # display SNMP data
    puts device.snmp.get_value('sysDescr.0')
    

All options supported by Netconf, Net::SCP and SNMP are supported in this gem too. The :target option is aliased to the SNMP :host option so there is no need to duplicate that option key.

## SUPPORT

This software is not officially supported by Juniper Networks, but by a team dedicated to helping customers, partners, and the development community.  To report bug-fixes, issues, susggestions, please contact David Gethings <dgethings@juniper.net>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
