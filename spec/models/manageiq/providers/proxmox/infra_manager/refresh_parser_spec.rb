require "spec_helper"

describe ManageIQ::Providers::Proxmox::InfraManager::RefreshParser do
  let(:ems) do
    FactoryBot.create(:ems_proxmox_infra,
                      :hostname => "proxmox.example.com")
  end

  let(:connection) { double("Connection") }
  let(:parser) { described_class.new(ems) }

  before do
    allow(ems).to receive(:connect).and_return(connection)
  end

  describe "#ems_inv_to_hashes" do
    let(:nodes_response) do
      double("Response",
             :status => 200,
             :body   => '{"data":[{"node":"node1","status":"online","pveversion":"7.4"}]}')
    end

    let(:qemu_response) do
      double("Response",
             :status => 200,
             :body   => '{"data":[{"vmid":100,"name":"test-vm","status":"running","cpus":2,"maxmem":2147483648,"maxdisk":10737418240}]}')
    end

    let(:lxc_response) do
      double("Response",
             :status => 200,
             :body   => '{"data":[{"vmid":200,"name":"test-container","status":"running"}]}')
    end

    let(:storage_response) do
      double("Response",
             :status => 200,
             :body   => '{"data":[{"storage":"local","type":"dir","total":107374182400,"avail":53687091200}]}')
    end

    let(:cluster_response) do
      double("Response",
             :status => 200,
             :body   => '{"data":[{"name":"cluster","type":"cluster"}]}')
    end

    before do
      allow(connection).to receive(:get).with("/api2/json/nodes").and_return(nodes_response)
      allow(connection).to receive(:get).with("/api2/json/nodes/node1/qemu").and_return(qemu_response)
      allow(connection).to receive(:get).with("/api2/json/nodes/node1/lxc").and_return(lxc_response)
      allow(connection).to receive(:get).with("/api2/json/nodes/node1/storage").and_return(storage_response)
      allow(connection).to receive(:get).with("/api2/json/cluster/status").and_return(cluster_response)
    end

    it "parses inventory correctly" do
      inventory = parser.ems_inv_to_hashes

      expect(inventory[:hosts]).to be_an(Array)
      expect(inventory[:hosts].first).to include(
        :type => "ManageIQ::Providers::Proxmox::InfraManager::Host",
        :name => "node1"
      )

      expect(inventory[:vms]).to be_an(Array)
      expect(inventory[:vms].first).to include(
        :type => "ManageIQ::Providers::Proxmox::InfraManager::Vm",
        :name => "test-vm"
      )

      expect(inventory[:storages]).to be_an(Array)
      expect(inventory[:storages].first).to include(
        :type => "ManageIQ::Providers::Proxmox::InfraManager::Storage",
        :name => "local"
      )
    end
  end
end
