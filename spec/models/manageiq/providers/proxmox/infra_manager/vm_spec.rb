require "spec_helper"

describe ManageIQ::Providers::Proxmox::InfraManager::Vm do
  let(:ems) do
    FactoryBot.create(:ems_proxmox_infra,
                      :hostname => "proxmox.example.com")
  end

  let(:vm) do
    FactoryBot.create(:vm_proxmox,
                      :ext_management_system => ems,
                      :ems_ref               => "node1/qemu/100",
                      :raw_power_state       => "running")
  end

  describe ".calculate_power_state" do
    it "converts 'running' to 'on'" do
      expect(described_class.calculate_power_state("running")).to eq("on")
    end

    it "converts 'stopped' to 'off'" do
      expect(described_class.calculate_power_state("stopped")).to eq("off")
    end

    it "converts unknown states to 'unknown'" do
      expect(described_class.calculate_power_state("unknown")).to eq("unknown")
    end
  end

  describe "#raw_start" do
    let(:connection) { double("Connection") }

    before do
      allow(ems).to receive(:with_provider_connection).and_yield(connection)
      allow(connection).to receive(:post).and_return(double("Response", :status => 200))
    end

    it "sends start command to Proxmox API" do
      expect(connection).to receive(:post).with("/api2/json/nodes/node1/qemu/100/status/start", {})
      vm.raw_start
    end
  end

  describe "#raw_stop" do
    let(:connection) { double("Connection") }

    before do
      allow(ems).to receive(:with_provider_connection).and_yield(connection)
      allow(connection).to receive(:post).and_return(double("Response", :status => 200))
    end

    it "sends stop command to Proxmox API" do
      expect(connection).to receive(:post).with("/api2/json/nodes/node1/qemu/100/status/stop", {})
      vm.raw_stop
    end
  end
end

