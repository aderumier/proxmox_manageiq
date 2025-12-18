module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class RefreshWorker < ManageIQ::Providers::BaseManager::RefreshWorker
          require_nested :Runner

          def self.ems_class
            ManageIQ::Providers::Proxmox::InfraManager
          end
        end
      end
    end
  end
end

