require "spec_helper"

describe ManageIQ::Providers::Proxmox::InfraManager do
  let(:ems) do
    FactoryBot.create(:ems_proxmox_infra,
                      :hostname => "proxmox.example.com",
                      :port     => 8006)
  end

  describe ".ems_type" do
    it "returns 'proxmox'" do
      expect(described_class.ems_type).to eq("proxmox")
    end
  end

  describe ".description" do
    it "returns 'Proxmox VE'" do
      expect(described_class.description).to eq("Proxmox VE")
    end
  end

  describe ".default_port" do
    it "returns 8006" do
      expect(described_class.default_port).to eq(8006)
    end
  end

  describe ".default_scheme" do
    it "returns 'https'" do
      expect(described_class.default_scheme).to eq("https")
    end
  end

  describe ".hostname_required?" do
    it "returns true" do
      expect(described_class.hostname_required?).to be true
    end
  end

  describe "#connect" do
    let(:connection) { double("Connection") }

    before do
      allow(described_class).to receive(:raw_connect).and_return(connection)
    end

    it "creates a connection with credentials" do
      ems.update(:authentication_type => "default")
      auth = ems.authentication_type(:default)
      auth.update(:userid => "testuser", :password => "testpass")

      expect(described_class).to receive(:raw_connect).with(
        "testuser",
        "testpass",
        "proxmox.example.com",
        8006,
        {}
      )

      ems.connect
    end
  end

  describe "#verify_credentials" do
    let(:connection) { double("Connection") }

    before do
      allow(described_class).to receive(:raw_connect).and_return(connection)
      allow(connection).to receive(:verify).and_return(true)
    end

    it "verifies credentials successfully" do
      ems.update(:authentication_type => "default")
      auth = ems.authentication_type(:default)
      auth.update(:userid => "testuser", :password => "testpass")

      expect(ems.verify_credentials).to be true
    end

    it "raises error on invalid credentials" do
      ems.update(:authentication_type => "default")
      auth = ems.authentication_type(:default)
      auth.update(:userid => "testuser", :password => "wrongpass")

      allow(connection).to receive(:verify).and_raise(StandardError.new("Authentication failed"))

      expect { ems.verify_credentials }.to raise_error(MiqException::MiqInvalidCredentialsError)
    end
  end
end

