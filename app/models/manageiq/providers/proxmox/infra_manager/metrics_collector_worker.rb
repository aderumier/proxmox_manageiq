module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class MetricsCollectorWorker < ManageIQ::Providers::BaseManager::MetricsCollectorWorker
          require_nested :Runner

          def self.ems_class
            ManageIQ::Providers::Proxmox::InfraManager
          end

          def self.settings_name
            :metrics_collector_worker_proxmox
          end
        end
      end
    end
  end
end

