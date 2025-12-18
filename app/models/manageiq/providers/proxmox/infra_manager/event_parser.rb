module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class EventParser
          def self.event_to_hash(event, ems_id)
            {
              :source     => "PROXMOX",
              :timestamp  => event[:timestamp] || Time.now.utc,
              :message    => event[:message] || event[:text],
              :vm_ems_ref => event[:vmid] ? "#{event[:node]}/#{event[:type]}/#{event[:vmid]}" : nil,
              :host_ems_ref => event[:node],
              :ems_id     => ems_id,
              :event_type => event[:type] || "unknown"
            }
          end
        end
      end
    end
  end
end

