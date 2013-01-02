require 'sloe'

describe Sloe do
  it "should return the correct version string" do
    Sloe::VERSION.should == Sloe::VERSION
  end
end