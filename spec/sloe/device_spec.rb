require 'spec_helper'

describe Sloe::Device do
  let(:host) { ENV['hosts'].split(':').first }
  let(:login) do
    {
      target: Envyable.load('tmp/env.yaml', host)['ip_address'],
      username: 'root',
      password: 'Juniper',
      port: Envyable.load('tmp/env.yaml', host)['ssh_port']
    }
  end
  subject(:dut) { Sloe::Device.new(login) }

  it 'logs in when new object is created' do
    expect(dut.state).to eq :NETCONF_OPEN
  end
end