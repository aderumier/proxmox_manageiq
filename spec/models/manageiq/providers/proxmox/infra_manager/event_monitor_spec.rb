require "spec_helper"

describe ManageIQ::Providers::Proxmox::InfraManager::EventMonitor do
  let(:ems) do
    FactoryBot.create(:ems_proxmox_infra,
                      :hostname => "proxmox.example.com")
  end

  let(:connection) { double("Connection") }
  let(:monitor) { described_class.new(ems) }

  before do
    allow(ems).to receive(:connect).and_return(connection)
  end

  describe "#initialize" do
    it "initializes with EMS" do
      expect(monitor.instance_variable_get(:@ems)).to eq(ems)
      expect(monitor.instance_variable_get(:@stop_requested)).to be false
    end
  end

  describe "#start" do
    it "resets stop flag and initializes last seen UPID" do
      monitor.instance_variable_set(:@stop_requested, true)
      allow(monitor).to receive(:initialize_last_seen_upid)
      
      monitor.start
      
      expect(monitor.instance_variable_get(:@stop_requested)).to be false
      expect(monitor).to have_received(:initialize_last_seen_upid)
    end
  end

  describe "#stop" do
    it "sets stop flag" do
      monitor.stop
      expect(monitor.instance_variable_get(:@stop_requested)).to be true
    end
  end

  describe "#fetch_events" do
    let(:tasks_response) do
      double("Response",
             :status => 200,
             :body   => '{"data":[{"upid":"UPID:node1:00001234:12345678:abcdef12:task:100:root@pam:","type":"vmmigrate","node":"node1","vmid":100,"status":"running","starttime":1234567890}]}')
    end

    before do
      allow(connection).to receive(:get).and_return(tasks_response)
      allow(JSON).to receive(:parse).and_return({
        "data" => [{
          "upid" => "UPID:node1:00001234:12345678:abcdef12:task:100:root@pam:",
          "type" => "vmmigrate",
          "node" => "node1",
          "vmid" => 100,
          "status" => "running",
          "starttime" => Time.now.to_i
        }]
      })
    end

    it "fetches and parses events" do
      events = monitor.send(:fetch_events)
      
      expect(events).to be_an(Array)
      expect(events.first).to include(:type => "vm_migrate")
    end
  end

  describe "#map_task_type_to_event_type" do
    it "maps Proxmox task types to ManageIQ event types" do
      expect(monitor.send(:map_task_type_to_event_type, "qmstart")).to eq("vm_poweron")
      expect(monitor.send(:map_task_type_to_event_type, "qmstop")).to eq("vm_poweroff")
      expect(monitor.send(:map_task_type_to_event_type, "qmshutdown")).to eq("vm_shutdown")
      expect(monitor.send(:map_task_type_to_event_type, "qmreboot")).to eq("vm_reboot")
      expect(monitor.send(:map_task_type_to_event_type, "qmcreate")).to eq("vm_create")
      expect(monitor.send(:map_task_type_to_event_type, "qmclone")).to eq("vm_clone")
      expect(monitor.send(:map_task_type_to_event_type, "qmdestroy")).to eq("vm_destroy")
      expect(monitor.send(:map_task_type_to_event_type, "qmmigrate")).to eq("vm_migrate")
      expect(monitor.send(:map_task_type_to_event_type, "qmsnapshot")).to eq("vm_snapshot")
      expect(monitor.send(:map_task_type_to_event_type, "unknown")).to eq("unknown")
    end
  end
end

