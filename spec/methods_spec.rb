require 'sloe'
require 'ruby-debug'

describe Sloe do

  before(:all) do
    @jnx_mibs = Dir.glob("./mibs/JUNIPER-*.yaml").map { |f| File.basename(f, '.yaml') }
    @args = {
      :target => 'capella',
      :username => 'netconf',
      :password => 'netconf',
      :mib_dir => './mibs',
      :mib_modules => ["SNMPv2-SMI", "SNMPv2-MIB", "IF-MIB", "IP-MIB", "TCP-MIB", "UDP-MIB"].concat(@jnx_mibs)
    }

    @dut = Sloe::Junos.new(@args)
  end

  context "SNMP API" do
    it "snmp.get_value() returns valid value" do
      @dut.snmp.get_value('sysDescr.0').should =~ /^Juniper Networks,/
    end
    it "snmp.get() returns one PDU" do
      @pdu = @dut.snmp.get('sysDescr.0')
      @pdu.varbind_list.should have(1).item
    end
    it "snmp.get_bulk() returns a list of PDUs" do
      @pdu = @dut.snmp.get_bulk(0, 5, 'system')
      @pdu.varbind_list.should have(5).items
    end
    it "snmp.get_next() returns one PDU" do
      @pdu = @dut.snmp.get_next('system')
      @pdu.varbind_list.should have(1).item
    end
    it "snmp.walk() returns a list of PDUs none of which are nil" do
      @dut.snmp.walk('system') { |vb| vb.should_not be_nil }
    end
  end

  context "JNX Enterprise MIBs" do
    it "jnxBoxDescr.0 has a valid value" do
      @dut.snmp.get_value('jnxBoxDescr.0').should =~ /^Juniper/
    end
  end

  context "NETCONF API" do
    it "rpc.get_interface_information() functioons without error" do
      lambda { @dut.rpc.get_interface_information() }.should_not raise_error
    end
    it "rpc.get_ospf_neighbor_information() functions without error" do
      lambda { @dut.rpc.get_ospf_neighbor_information() }.should_not raise_error
    end
  end

  context "SCP API" do
    it "scp.download() functions without error" do
      lambda { @dut.scp.download!('/config/juniper.conf.gz', '/var/tmp/juniper.conf.gz') }.should_not raise_error
      File.delete('/var/tmp/juniper.conf.gz')
    end
    it "scp.upload() functions without error" do
      File.new('/var/tmp/test', 'w+')
      lambda { @dut.scp.upload!('/var/tmp/test', 'test') }.should_not raise_error
      @dut.rpc.file_delete(:path => 'test')
      File.delete('/var/tmp/test')
    end
  end

  context "CLI API" do
    it "cli.('show version') functions without error" do
      lambda { @dut.cli("show version") }.should_not raise_error
    end
    it "cli.('show version') contains OS information" do
      @dut.cli("show version").should =~ /JUNOS Base OS/
    end
  end
end