require 'sloe'
require 'ruby-debug'

describe Sloe do

  before(:all) do
    @jnx_mibs = Dir.glob("./mibs/JUNIPER-*.yaml").map { |f| File.basename(f, '.yaml') }
    @args = {
      :target => 'capella',
      :username => 'dgethings',
      :password => 'mcisamilf',
      :mib_dir => './mibs',
      :mib_modules => ["SNMPv2-SMI", "SNMPv2-MIB", "IF-MIB", "IP-MIB", "TCP-MIB", "UDP-MIB"].concat(@jnx_mibs)
    }

    @dut = Sloe::Device.new(@args)
  end

  context "SNMP method" do
    it "should return value for snmp.get_value()" do
      @dut.snmp.get_value('sysDescr.0').should =~ /^Juniper Networks,/
    end
    it "should return PDU for snmp.get()" do
      @pdu = @dut.snmp.get('sysDescr.0')
      @pdu.varbind_list.should have(1).item
    end
    it "should return list of PDUs for snmp.get_bulk()" do
      @pdu = @dut.snmp.get_bulk(0, 5, 'system')
      @pdu.varbind_list.should have(5).items
    end
    it "should return PDU snmp.get_next()" do
      @pdu = @dut.snmp.get_next('system')
      @pdu.varbind_list.should have(1).item
    end
    it "should return list of PDUs for snmp.walk()" do
      @dut.snmp.walk('system') { |vb| vb.should_not be_nil }
    end
  end

  context "JNX Enterprise MIBs" do
    it "should have valid jnxBoxDescr value" do
      @dut.snmp.get_value('jnxBoxDescr.0').should =~ /^Juniper/
    end
  end

  context "NETCONF API" do
    it "get_interface_information()" do
      lambda { @dut.rpc.get_interface_information() }.should_not raise_error
    end
    it "get_ospf_neighbor_information()" do
      lambda { @dut.rpc.get_ospf_neighbor_information() }.should_not raise_error
    end
  end

end