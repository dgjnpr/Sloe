require 'spec_helper'

RSpec.describe Sloe do
  let(:host) { ENV['hosts'].split(':').first }
  let(:login) do
    {
      target: Envyable.load('tmp/env.yaml', host)['ip_address'],
      username: 'root',
      password: 'Juniper',
      port: Envyable.load('tmp/env.yaml', host)['ssh_port'],
      snmp_port: 1161
    }
  end
  subject(:dut) { Sloe::Device.new(login) }

  context 'SNMP API' do
    it 'snmp.get_value returns valid value' do
      expect(dut.snmp.get_value('sysDescr.0')).to include('Juniper Networks')
    end
    it 'snmp.get returns one PDU' do
      expect(dut.snmp.get('sysDescr.0').varbind_list.size).to eq(1)
    end
    it 'snmp.get_bulk returns a list of PDUs' do
      expect(dut.snmp.get_bulk(0, 5, 'system').varbind_list.size).to eq(5)
    end
    it 'snmp.get_next returns one PDU' do
      expect(dut.snmp.get_next('system').varbind_list.size).to eq(1)
    end
    it 'snmp.walk returns a list of PDUs' do
      vbs = []
      dut.snmp.walk('system') { |vb| vbs << vb }
      expect(vbs.size).to be > 0
    end
  end

  context 'NETCONF API' do
    it 'rpc.get_interface_information functions without error' do
      expect { dut.rpc.get_interface_information }.not_to raise_error
    end
    it 'rpc.get_ospf_neighbor_information functions without error' do
      expect { dut.rpc.get_ospf_neighbor_information }.not_to raise_error
    end
  end

  context 'SCP API' do
    it 'scp.download() functions without error' do
      expect { dut.scp.download!('/config/juniper.conf.gz', '/var/tmp/juniper.conf.gz') }.not_to raise_error
      File.delete('/var/tmp/juniper.conf.gz')
    end
    it 'scp.upload() functions without error' do
      File.new('/var/tmp/test', 'w+')
      expect { dut.scp.upload!('/var/tmp/test', 'test') }.not_to raise_error
      dut.rpc.file_delete(path: 'test')
      File.delete('/var/tmp/test')
    end
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
end
