require "spec_helper"

describe ManageIQ::Providers::Proxmox::InfraManager::Vm::Snapshots do
  let(:ems) do
    FactoryBot.create(:ems_proxmox_infra,
                      :hostname => "proxmox.example.com")
  end

  let(:vm) do
    FactoryBot.create(:vm_proxmox,
                      :ext_management_system => ems,
                      :ems_ref               => "node1/qemu/100")
  end

  let(:connection) { double("Connection") }

  before do
    allow(ems).to receive(:with_provider_connection).and_yield(connection)
  end

  describe "#raw_create_snapshot" do
    let(:snapshot_response) do
      double("Response",
             :status => 200,
             :body   => '{"data":"UPID:node1:00001234:12345678:abcdef12:snapshot:100:root@pam:"}')
    end

    let(:task_response) do
      double("Response",
             :status => 200,
             :body   => '{"data":{"status":"stopped","exitstatus":"OK"}}')
    end

    before do
      allow(connection).to receive(:post).and_return(snapshot_response)
      allow(connection).to receive(:get).and_return(task_response)
      allow(JSON).to receive(:parse).and_return({
        "data" => "UPID:node1:00001234:12345678:abcdef12:snapshot:100:root@pam:"
      }, {
        "data" => {"status" => "stopped", "exitstatus" => "OK"}
      })
    end

    it "creates a snapshot" do
      expect(connection).to receive(:post).with(
        "/api2/json/nodes/node1/qemu/100/snapshot",
        hash_including(:snapname => "test-snapshot")
      )

      vm.raw_create_snapshot(:name => "test-snapshot")
    end
  end

  describe "#raw_delete_snapshot" do
    let(:delete_response) do
      double("Response",
             :status => 200,
             :body   => '{"data":"UPID:node1:00001234:12345678:abcdef12:snapshot:100:root@pam:"}')
    end

    before do
      allow(connection).to receive(:delete).and_return(delete_response)
      allow(JSON).to receive(:parse).and_return({
        "data" => "UPID:node1:00001234:12345678:abcdef12:snapshot:100:root@pam:"
      })
    end

    it "deletes a snapshot" do
      expect(connection).to receive(:delete).with(
        "/api2/json/nodes/node1/qemu/100/snapshot/test-snapshot"
      )

      vm.raw_delete_snapshot("test-snapshot")
    end
  end
end

