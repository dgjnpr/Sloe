require 'sloe/setup'

describe Sloe::Setup do
  context "apply configuration change" do
    it "to one device" do
      @setup = Sloe::Setup.new( './test/topo1' ).should_not raise_error
    end
    it "to muliple devices" 
  end

  context "Apply new Junos version" do
    it "to one device" 
    it "to multiple devices" 
  end

  context "Apply new Junos version and configuration" do
    it "to one device" 
    it "to multiple devices" 
  end
end
