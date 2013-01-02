require 'sloe'

describe Sloe do

  before(:all) do
    @dut = Sloe::Device.new('capella', 'dgethings', 'mcisamilf')
  end

  it "should return the correct version string" do
    Sloe::VERSION.should == Sloe::VERSION
  end

end