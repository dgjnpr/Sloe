require 'spec_helper'

describe Sloe do
  let(:login) { {target: 'crtj-0dc1-0001', username: 'netadmin', password: 'pass123'} }
  context "invoked with block" do
    it "calls Netconf RPC" do
      hostname = ''
      Sloe::Device.new(login) { |dut| 
        hostname = dut.rpc.get_system_information.xpath('//host-name').text
      }
      expect(hostname).to include login[:target]
    end

    it "calls SNMP RPC" do
      hostname = ''
      Sloe::Device.new (login) { |dut| 
        hostname = dut.snmp.get_value( 'sysName.0' ).to_s
      }
      expect(hostname).to include login[:target]
    end
  end

  context "Junos extensions" do
    it "Sloe::Junos responds to Junos specific RPCs" do
      expect( Sloe::Junos.new(login).rpc ).to respond_to(:lock_configuration)
    end
    it "Sloe::Device does not respond to Junos specific RPCs" do
      expect( Sloe::Device.new(login).rpc ).to_not respond_to(:lock_configuration)
    end
  end
end