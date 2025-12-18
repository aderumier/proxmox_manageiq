module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class Host < ManageIQ::Providers::InfraManager::Host
          def self.display_name(number = 1)
            n_("Host (Proxmox)", "Hosts (Proxmox)", number)
          end

          def verify_credentials(auth_type = nil, options = {})
            # Proxmox hosts are managed through the cluster API
            # Credentials are verified at the EMS level
            true
          end
        end
      end
    end
  end
end

