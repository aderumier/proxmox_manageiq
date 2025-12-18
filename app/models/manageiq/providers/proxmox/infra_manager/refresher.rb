module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class Refresher < ManageIQ::Providers::BaseManager::Refresher
          include ::EmsRefresh::Refreshers::EmsRefresherMixin

          def parse_legacy_inventory(ems)
            ManageIQ::Providers::Proxmox::InfraManager::RefreshParser.ems_inv_to_hashes(ems)
          end

          def post_process_refresh_classes
            [::Vm, ::Host]
          end
        end
      end
    end
  end
end

