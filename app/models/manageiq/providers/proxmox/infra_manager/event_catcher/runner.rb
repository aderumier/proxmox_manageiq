module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class EventCatcher
          class Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
            def event_monitor_handle
              @event_monitor_handle ||= begin
                require "manageiq/providers/proxmox/infra_manager/event_monitor"
                ManageIQ::Providers::Proxmox::InfraManager::EventMonitor.new(ems)
              end
            end

            def reset_event_monitor_handle
              @event_monitor_handle = nil
            end

            def stop_event_monitor
              @event_monitor_handle&.stop
            ensure
              reset_event_monitor_handle
            end

            def monitor_events
              event_monitor_handle.start
              event_monitor_running
              event_monitor_handle.each_batch do |events|
                @queue.enq(events)
                sleep_poll_normal
              end
            ensure
              stop_event_monitor
            end

            def process_event(event)
              ManageIQ::Providers::Proxmox::InfraManager::EventParser.event_to_hash(event, ems.id)
            end
          end
        end
      end
    end
  end
end

