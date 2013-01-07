require 'sloe'
require 'ruby-debug'

describe Sloe do

  before(:all) do
    @dut = Sloe::Device.new('capella', 'dgethings', 'mcisamilf')
  end

  context "SNMP method" do
    it "should return value for snmp_get()" do
      @dut.snmp_get('sysDescr.0').should =~ /^Juniper Networks,/
    end
    it "should return PDU for snmp_get_pdu()" do
      @pdu = @dut.snmp_get_pdu('sysDescr.0')
      @pdu.varbind_list.should have(1).item
    end
    it "should return list of PDUs for snmp_get_bulk()" do
      @pdu = @dut.snmp_get_bulk(0, 5, 'system')
      @pdu.varbind_list.should have(5).items
    end
    it "should return PDU snmp_get_next()" do
      @pdu = @dut.snmp_get_next('system')
      @pdu.varbind_list.should have(1).item
    end
    it "should return list of PDUs for snmp_walk()" do
      pending("snmp_walk() not yet implemented")
      @dut.snmp_walk('system') { |vb| vb.should_not be_nil }
    end
  end

  context "JNX Enterprise MIBs" do
    it "should have valid jnxBoxDescr value" do
      @dut.snmp_get('jnxBoxDescr.0').should =~ /^Juniper/
    end
  end

  context "NETCONF API" do
    it "get_interface_information()" do
      @dut.rpc.get_interface_information().should_not be_nil
    end
    it "get_interface_information(:interface => 'fxp0')" do
      pending("bug to be fixed in Netconf gem")
      @dut.rpc.get_interface_information(:interface => 'fxp0').should_not be_nil
    end
    it "get_ospf_neighbor_information()" do
      @dut.rpc.get_ospf_neighbor_information().should_not be_nil
    end
    it "get_ospf_neighbor_information(:area => '0.0.0.9')" do
      @dut.rpc.get_ospf_neighbor_information(:area => '0.0.0.9').should_not be_nil
    end
  end

end