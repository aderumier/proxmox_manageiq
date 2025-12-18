require "spec_helper"
require "manageiq/providers/proxmox/infra_manager/connection"

describe ManageIQ::Providers::Proxmox::InfraManager::Connection do
  let(:connection) do
    described_class.new(
      :username => "testuser",
      :password => "testpass",
      :hostname => "proxmox.example.com",
      :port     => 8006,
      :scheme   => "https"
    )
  end

  let(:faraday_connection) { double("Faraday::Connection") }
  let(:response) { double("Response", :status => 200, :body => '{"data":{"ticket":"test-ticket","CSRFPreventionToken":"test-token"}}') }

  describe "#initialize" do
    it "sets connection parameters" do
      expect(connection.username).to eq("testuser")
      expect(connection.password).to eq("testpass")
      expect(connection.hostname).to eq("proxmox.example.com")
      expect(connection.port).to eq(8006)
      expect(connection.scheme).to eq("https")
    end

    it "uses default port and scheme" do
      conn = described_class.new(
        :username => "testuser",
        :password => "testpass",
        :hostname => "proxmox.example.com"
      )
      expect(conn.port).to eq(8006)
      expect(conn.scheme).to eq("https")
    end
  end

  describe "#base_url" do
    it "returns the correct base URL" do
      expect(connection.base_url).to eq("https://proxmox.example.com:8006")
    end
  end

  describe "#authenticate" do
    before do
      allow(connection).to receive(:connect).and_return(faraday_connection)
      allow(faraday_connection).to receive(:post).and_return(response)
      allow(JSON).to receive(:parse).and_return({
        "data" => {
          "ticket" => "test-ticket",
          "CSRFPreventionToken" => "test-token"
        }
      })
    end

    it "authenticates and sets ticket" do
      expect(connection.authenticate).to be true
      expect(connection.instance_variable_get(:@ticket)).to eq("test-ticket")
      expect(connection.instance_variable_get(:@csrf_token)).to eq("test-token")
    end

    it "raises error on authentication failure" do
      error_response = double("Response", :status => 401, :body => '{"errors":[{"message":"Invalid credentials"}]}')
      allow(faraday_connection).to receive(:post).and_return(error_response)
      allow(JSON).to receive(:parse).and_return({"errors" => [{"message" => "Invalid credentials"}]})

      expect { connection.authenticate }.to raise_error(/Authentication failed/)
    end
  end

  describe "#get" do
    let(:get_response) { double("Response", :status => 200, :body => '{"data":[]}') }

    before do
      allow(connection).to receive(:connect).and_return(faraday_connection)
      allow(connection).to receive(:authenticate)
      connection.instance_variable_set(:@ticket, "test-ticket")
      allow(faraday_connection).to receive(:get).and_return(get_response)
      allow(connection).to receive(:handle_response).and_return(get_response)
    end

    it "makes a GET request with authentication" do
      expect(faraday_connection).to receive(:get).with("/api2/json/nodes", {}) do |path, params, &block|
        req = double("Request")
        allow(req).to receive(:headers=)
        block.call(req) if block
        get_response
      end

      connection.get("/api2/json/nodes")
    end
  end

  describe "#post" do
    let(:post_response) { double("Response", :status => 200, :body => '{"data":{}}') }

    before do
      allow(connection).to receive(:connect).and_return(faraday_connection)
      allow(connection).to receive(:authenticate)
      connection.instance_variable_set(:@ticket, "test-ticket")
      connection.instance_variable_set(:@csrf_token, "test-token")
      allow(faraday_connection).to receive(:post).and_return(post_response)
      allow(connection).to receive(:handle_response).and_return(post_response)
    end

    it "makes a POST request with form data" do
      expect(faraday_connection).to receive(:post).with("/api2/json/nodes/test/qemu/100/status/start", "action=start") do |path, body, &block|
        req = double("Request")
        allow(req).to receive(:headers=)
        block.call(req) if block
        post_response
      end

      connection.post("/api2/json/nodes/test/qemu/100/status/start", {:action => "start"})
    end
  end
end

