require "json"

module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class EventMonitor
          def initialize(ems)
            @ems = ems
            @connection = ems.connect
            @stop_requested = false
            @last_seen_upid = nil
            @last_poll_time = Time.now
          end

          def start
            @stop_requested = false
            @last_poll_time = Time.now
            # Get the most recent task ID to start tracking from
            initialize_last_seen_upid
          end

          def stop
            @stop_requested = true
          end

          def each_batch
            until @stop_requested
              events = fetch_events
              yield events if events.any?
              sleep(poll_interval)
            end
          end

          private

          def poll_interval
            # Poll every 30 seconds by default, configurable
            @ems.options&.dig(:event_poll_interval) || 30
          end

          def initialize_last_seen_upid
            begin
              response = @connection.get("/api2/json/cluster/tasks", :limit => 1)
              data = JSON.parse(response.body)
              tasks = data["data"] || []
              @last_seen_upid = tasks.first&.dig("upid") if tasks.any?
            rescue => e
              $log.warn("Could not initialize last seen UPID: #{e.message}")
            end
          end

          def fetch_events
            events = []
            begin
              # Get recent tasks from Proxmox
              params = {}
              params[:since] = @last_poll_time.to_i if @last_poll_time
              
              response = @connection.get("/api2/json/cluster/tasks", params)
              data = JSON.parse(response.body)
              tasks = data["data"] || []

              # Filter tasks we haven't seen yet
              new_tasks = if @last_seen_upid
                tasks.select { |t| t["upid"] != @last_seen_upid && task_relevant?(t) }
              else
                tasks.select { |t| task_relevant?(t) }
              end

              new_tasks.each do |task|
                event = build_event_from_task(task)
                events << event if event
                
                # Update last seen UPID
                @last_seen_upid = task["upid"] if task["upid"]
              end

              @last_poll_time = Time.now
            rescue => e
              $log.error("Error fetching Proxmox events: #{e.class.name}: #{e.message}")
              $log.error(e.backtrace.join("\n"))
            end

            events
          end

          def task_relevant?(task)
            # Only include tasks that are relevant for event monitoring
            # Include running tasks and recently completed tasks (within last 5 minutes)
            return true if task["status"] == "running"
            
            if task["starttime"]
              start_time = Time.at(task["starttime"].to_i)
              return true if (Time.now - start_time) < 300 # 5 minutes
            end
            
            false
          end

          def build_event_from_task(task)
            {
              :timestamp => Time.at(task["starttime"].to_i),
              :message   => task["type"] || task["id"] || "unknown",
              :node      => task["node"],
              :vmid      => task["vmid"],
              :type      => map_task_type_to_event_type(task["type"]),
              :text      => task["type"] || task["id"] || "unknown",
              :upid      => task["upid"],
              :status    => task["status"]
            }
          end

          def map_task_type_to_event_type(task_type)
            # Map Proxmox task types to ManageIQ event types
            case task_type.to_s.downcase
            when /start/
              "vm_poweron"
            when /stop/
              "vm_poweroff"
            when /shutdown/
              "vm_shutdown"
            when /reboot/
              "vm_reboot"
            when /create/
              "vm_create"
            when /clone/
              "vm_clone"
            when /delete/, /destroy/
              "vm_destroy"
            when /migrate/
              "vm_migrate"
            when /snapshot/
              "vm_snapshot"
            else
              "unknown"
            end
          end
        end
      end
    end
  end
end

