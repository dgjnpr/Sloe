require 'spec_helper'

describe Sloe do
  let(:host) { ENV['hosts'].split(':').first }
  let(:login) do
    {
      target: Envyable.load('/tmp/env.yaml', host)['ip_address'],
      username: 'root',
      password: 'Juniper',
      port: Envyable.load('/tmp/env.yaml', host)['ssh_port']
    }
  end

  context 'invoked with block' do
    it 'calls Netconf RPC' do
      hostname = ''
      Sloe::Device.new(login) do |dut|
        hostname = dut.rpc.get_system_information.xpath('//host-name').text
      end
      expect(hostname).to include host
    end

    it 'calls SNMP RPC' do
      hostname = ''
      Sloe::Device.new(login) do |dut|
        hostname = dut.snmp.get_value('sysName.0').to_s
      end
      expect(hostname).to include host
    end
  end

  context 'Junos extensions' do
    it 'Sloe::Junos responds to Junos specific RPCs' do
      expect(Sloe::Junos.new(login).rpc).to respond_to(:lock_configuration)
    end
    it 'Sloe::Device does not respond to Junos specific RPCs' do
      expect(Sloe::Device.new(login).rpc).to_not respond_to(:lock_configuration)
    end
  end
end