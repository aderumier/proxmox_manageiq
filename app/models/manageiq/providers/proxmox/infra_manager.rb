module ManageIQ
  module Providers
    module Proxmox
      class InfraManager < ManageIQ::Providers::InfraManager
        require_nested :AuthKeyPair
        require_nested :RefreshWorker
        require_nested :Refresher
        require_nested :Vm
        require_nested :Host
        require_nested :Template
        require_nested :Storage
        require_nested :Cluster
        require_nested :Network
        require_nested :EventCatcher
        require_nested :EventParser
        require_nested :EventMonitor
        require_nested :MetricsCollectorWorker
        require_nested :MetricsCollector
        require_nested :Exceptions

        include ManageIQ::Providers::Proxmox::ManagerMixin

        supports :create
        supports :refresh_ems
        supports :provisioning

        def self.ems_type
          @ems_type ||= "proxmox".freeze
        end

        def self.description
          @description ||= "Proxmox VE".freeze
        end

        def self.default_blacklisted_event_names
          %w[
            system
            user
          ]
        end

        def connect(options = {})
          raise "no credentials defined" if missing_credentials?(options[:auth_type])

          username = options[:user] || authentication_userid(options[:auth_type])
          password = options[:pass] || authentication_password(options[:auth_type])
          hostname = options[:hostname] || hostname
          port = options[:port] || default_port

          self.class.raw_connect(username, password, hostname, port, options)
        end

        def verify_credentials(auth_type = nil, options = {})
          begin
            connection = connect(options.merge(:auth_type => auth_type))
            connection.verify
          rescue => err
            raise MiqException::MiqInvalidCredentialsError, err.message
          end

          true
        end

        def self.raw_connect(username, password, hostname, port = nil, options = {})
          require "manageiq/providers/proxmox/infra_manager/connection"
          Connection.new(
            :username => username,
            :password => password,
            :hostname => hostname,
            :port     => port || default_port,
            :scheme   => options[:scheme] || default_scheme
          )
        end

        def self.validate_authentication_args(params)
          return [:default, "missing"] if params[:username].blank?
          return [:default, "missing"] if params[:password].blank?

          # TODO: Add validation for hostname/ip
          # return [:default, "missing"] if params[:hostname].blank?

          [:default, nil]
        end

        def self.hostname_required?
          true
        end

        def self.default_port
          8006
        end

        def self.default_scheme
          "https"
        end

        def refresh
          EmsRefresh.queue_refresh(self)
        end

        def with_provider_connection(options = {})
          raise "no block given" unless block_given?
          _log.debug("Connecting through #{self.class.name}: [#{name}]")
          yield connect(options)
        end

        def self.catalog_types
          {"proxmox" => N_("Proxmox")}
        end
      end
    end
  end
end

