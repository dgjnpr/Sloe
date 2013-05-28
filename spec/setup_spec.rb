require 'sloe/setup'

describe Sloe::Setup do
  context "apply configuration change" do
    it "to one device" do
      pending "known working"
      @setup = Sloe::Setup.new( './test/topo1' )
      @setup.complete?.should be true
    end
    it "to muliple devices" do
      pending "known working"
      @setup = Sloe::Setup.new( './test/topo2' )
      @setup.complete?.should be true
    end
  end

  context "Apply new Junos version" do
    it "to one device" do
      @setup = Sloe::Setup.new( './test/topo3' )
      @setup.complete?.should be true
    end      
    it "to multiple devices" do
      @setup = Sloe::Setup.new( './test/topo4' )
      @setup.complete?.should be true
    end
  end

  context "Apply new Junos version and configuration" do
    it "to one device" do
      @setup = Sloe::Setup.new( './test/topo5' )
      @setup.complete?.should be true
    end
    it "to multiple devices" do
      @setup = Sloe::Setup.new( './test/topo6' )
      @setup.complete?.should be true
    end
  end
end
