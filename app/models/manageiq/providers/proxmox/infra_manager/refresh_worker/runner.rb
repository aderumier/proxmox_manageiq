module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class RefreshWorker
          class Runner < ManageIQ::Providers::BaseManager::RefreshWorker::Runner
            def do_work
              self.class.ems_class.find_each do |ems|
                next unless ems.enabled

                EmsRefresh.queue_refresh(ems)
              end
            end
          end
        end
      end
    end
  end
end

