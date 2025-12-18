module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class Template < ManageIQ::Providers::InfraManager::Template
          def self.display_name(number = 1)
            n_("Template (Proxmox)", "Templates (Proxmox)", number)
          end
        end
      end
    end
  end
end

