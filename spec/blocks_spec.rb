require 'sloe'
require 'sloe/junos'

describe Sloe do
  context "invoked with block" do
    before(:all) do
      @login = {
        :target => 'capella',
        :username => 'netconf',
        :password => 'netconf'
      }
      @hostname = ''
    end

    it "calls Netconf RPC" do
      Sloe::Device.new( @login ) { |dut| 
        sw_info = dut.rpc.get_system_information
        @hostname = sw_info.xpath('//host-name').text
      }
      @hostname.should include @login[:target]
    end

    it "calls SNMP RPC" do
      Sloe::Device.new ( @login ) { |dut| 
        @hostname = dut.snmp.get_value( 'sysName.0' ).to_s
      }
      @hostname.should include @login[:target]
    end

  end

  context "Junos extensions" do
    before(:all) do
      @login = {
        :target => 'capella',
        :username => 'netconf',
        :password => 'netconf'
      }
    end

    it "Sloe::Junos responds to Junos specific RPCs" do
      Sloe::Junos.new ( @login ) { |dut|
        dut.rpc.respond_to?(:lock_configuration).should be true
      }
    end
    it "Sloe::Device does not respond to Junos specific RPCs" do
      Sloe::Device.new ( @login ) { |dut|
        dut.rpc.respond_to?(:lock_configuration).should be false
      }
    end

  end
end