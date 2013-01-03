require 'sloe'
require 'ruby-debug'

describe Sloe do

  before(:all) do
    @dut = Sloe::Device.new('capella', 'dgethings', 'mcisamilf')
  end

  context "ifd tests" do
    interface = 'ge-9/0/0'

    it "should successfully get interface information" do
      expect(@dut.get_ifd(interface)).not_to be_nil
    end
    it "should return a SNMP value" do
      @dut.ifd_snmp_inOctets(interface).should >= 0
    end
    it "should return a CLI value" do
      @dut.ifd_cli_inOctets(interface).should >= 0
    end
    it "should have same values for CLI and SNMP" do
      @dut.ifd_cli_inOctets(interface).should == @dut.ifd_snmp_inOctets(interface)
    end
  end

  context "ifl tests" do
    interface = 'ge-9/0/0.0'

    it "should successfully get interface information" do
      expect(@dut.get_ifd(interface)).not_to be_nil
    end
    it "should return a SNMP value" do
      @dut.ifd_snmp_inOctets(interface).should >= 0
    end
    it "should return a CLI value" do
      @dut.ifd_cli_inOctets(interface).should >= 0
    end
    it "should have same values for CLI and SNMP" do
      @dut.ifd_cli_inOctets(interface).should == @dut.ifd_snmp_inOctets(interface)
    end    
  end
end