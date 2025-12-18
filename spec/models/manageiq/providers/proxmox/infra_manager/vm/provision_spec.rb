require "spec_helper"

describe ManageIQ::Providers::Proxmox::InfraManager::Vm::Provision do
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

  describe "#raw_clone_vm" do
    let(:clone_response) do
      double("Response",
             :status => 200,
             :body   => '{"data":"UPID:node1:00001234:12345678:abcdef12:clone:100:root@pam:"}')
    end

    let(:task_response) do
      double("Response",
             :status => 200,
             :body   => '{"data":{"status":"stopped","exitstatus":"OK"}}')
    end

    before do
      allow(connection).to receive(:post).and_return(clone_response)
      allow(connection).to receive(:get).and_return(task_response)
      allow(JSON).to receive(:parse).and_return({
        "data" => "UPID:node1:00001234:12345678:abcdef12:clone:100:root@pam:"
      }, {
        "data" => {"status" => "stopped", "exitstatus" => "OK"}
      })
    end

    it "clones a VM" do
      expect(connection).to receive(:post).with(
        "/api2/json/nodes/node1/qemu/100/clone",
        hash_including(:newid => "200", :name => "test-clone")
      )

      vm.raw_clone_vm(:vmid => "200", :name => "test-clone")
    end
  end
end

