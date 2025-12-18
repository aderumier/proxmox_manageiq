require "spec_helper"
require "support/vcr"

describe "Proxmox Connection Integration", :vcr do
  let(:hostname) { ENV["PROXMOX_HOSTNAME"] || "proxmox.example.com" }
  let(:username) { ENV["PROXMOX_USERNAME"] || "root@pam" }
  let(:password) { ENV["PROXMOX_PASSWORD"] || "password" }

  let(:connection) do
    ManageIQ::Providers::Proxmox::InfraManager::Connection.new(
      :username => username,
      :password => password,
      :hostname => hostname,
      :port     => 8006
    )
  end

  describe "authentication" do
    it "authenticates successfully", :vcr => { :cassette_name => "proxmox/authentication" } do
      skip "Set PROXMOX_HOSTNAME, PROXMOX_USERNAME, PROXMOX_PASSWORD to run integration tests" unless ENV["PROXMOX_HOSTNAME"]
      
      expect { connection.authenticate }.not_to raise_error
      expect(connection.instance_variable_get(:@ticket)).not_to be_nil
    end
  end

  describe "API calls" do
    before do
      connection.authenticate
    end

    it "gets cluster nodes", :vcr => { :cassette_name => "proxmox/nodes" } do
      skip "Set PROXMOX_HOSTNAME, PROXMOX_USERNAME, PROXMOX_PASSWORD to run integration tests" unless ENV["PROXMOX_HOSTNAME"]
      
      response = connection.get("/api2/json/nodes")
      expect(response.status).to eq(200)
      
      data = JSON.parse(response.body)
      expect(data["data"]).to be_an(Array)
    end

    it "gets VMs from a node", :vcr => { :cassette_name => "proxmox/vms" } do
      skip "Set PROXMOX_HOSTNAME, PROXMOX_USERNAME, PROXMOX_PASSWORD to run integration tests" unless ENV["PROXMOX_HOSTNAME"]
      
      # First get nodes
      nodes_response = connection.get("/api2/json/nodes")
      nodes = JSON.parse(nodes_response.body)["data"]
      return if nodes.empty?
      
      node = nodes.first["node"]
      response = connection.get("/api2/json/nodes/#{node}/qemu")
      expect(response.status).to eq(200)
      
      data = JSON.parse(response.body)
      expect(data["data"]).to be_an(Array)
    end
  end
end

