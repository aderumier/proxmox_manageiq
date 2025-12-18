module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class EventCatcher < ManageIQ::Providers::BaseManager::EventCatcher
          require_nested :Runner

          def self.ems_class
            ManageIQ::Providers::Proxmox::InfraManager
          end

          def self.settings_name
            :event_catcher_proxmox
          end
        end
      end
    end
  end
end

