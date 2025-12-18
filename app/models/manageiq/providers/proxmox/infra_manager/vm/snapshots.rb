module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class Vm
          module Snapshots
            extend ActiveSupport::Concern

            def raw_create_snapshot(options)
              ext_management_system.with_provider_connection do |connection|
                snapshot_name = options[:name] || "snapshot-#{Time.now.to_i}"
                description = options[:description]
                
                parts = ems_ref.split("/")
                node = parts[0]
                vm_type = parts[1]
                vmid = parts[2]
                
                params = {
                  :snapname => snapshot_name
                }
                params[:description] = description if description
                
                response = connection.post("/api2/json/nodes/#{node}/#{vm_type}/#{vmid}/snapshot", params)
                
                if response.status == 200
                  data = JSON.parse(response.body)
                  wait_for_task(connection, data["data"])
                  snapshot_name
                else
                  raise "Failed to create snapshot: #{response.body}"
                end
              end
            end

            def raw_delete_snapshot(snapshot_name)
              ext_management_system.with_provider_connection do |connection|
                parts = ems_ref.split("/")
                node = parts[0]
                vm_type = parts[1]
                vmid = parts[2]
                
                response = connection.delete("/api2/json/nodes/#{node}/#{vm_type}/#{vmid}/snapshot/#{snapshot_name}")
                
                if response.status == 200
                  data = JSON.parse(response.body)
                  wait_for_task(connection, data["data"]) if data["data"]
                  true
                else
                  raise "Failed to delete snapshot: #{response.body}"
                end
              end
            end

            def raw_revert_to_snapshot(snapshot_name)
              ext_management_system.with_provider_connection do |connection|
                parts = ems_ref.split("/")
                node = parts[0]
                vm_type = parts[1]
                vmid = parts[2]
                
                response = connection.post("/api2/json/nodes/#{node}/#{vm_type}/#{vmid}/snapshot/#{snapshot_name}/rollback", {})
                
                if response.status == 200
                  data = JSON.parse(response.body)
                  wait_for_task(connection, data["data"]) if data["data"]
                  true
                else
                  raise "Failed to revert to snapshot: #{response.body}"
                end
              end
            end

            def get_snapshots
              ext_management_system.with_provider_connection do |connection|
                parts = ems_ref.split("/")
                node = parts[0]
                vm_type = parts[1]
                vmid = parts[2]
                
                response = connection.get("/api2/json/nodes/#{node}/#{vm_type}/#{vmid}/snapshot")
                data = JSON.parse(response.body)
                data["data"] || []
              end
            end

            private

            def wait_for_task(connection, upid, timeout = 300)
              return unless upid
              
              start_time = Time.now
              
              while (Time.now - start_time) < timeout
                task_response = connection.get("/api2/json/cluster/tasks/#{upid}")
                task_data = JSON.parse(task_response.body)["data"]
                
                status = task_data["status"]
                return if status == "stopped" # Completed
                raise "Task failed: #{task_data['exitstatus']}" if status == "failed"
                
                sleep(2) # Poll every 2 seconds
              end
              
              raise "Task timeout after #{timeout} seconds"
            end
          end
        end
      end
    end
  end
end

