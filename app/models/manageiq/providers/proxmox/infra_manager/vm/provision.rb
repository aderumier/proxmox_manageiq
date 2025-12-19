module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class Vm
          module Provision
            extend ActiveSupport::Concern

            def raw_create_vm(options)
              ext_management_system.with_provider_connection do |connection|
                node = options[:node] || find_available_node(connection)
                vm_type = options[:vm_type] || "qemu"
                vmid = options[:vmid] || find_next_vmid(connection, node)

                create_vm_from_template(connection, node, vm_type, vmid, options)
              end
            end

            def raw_clone_vm(options)
              ext_management_system.with_provider_connection do |connection|
                source_vm = options[:source_vm]
                new_vmid = options[:vmid] || find_next_vmid(connection, options[:node])
                new_name = options[:name] || "#{source_vm.name}-clone"

                clone_vm(connection, source_vm, new_vmid, new_name, options)
              end
            end

            private

            def find_available_node(connection)
              response = connection.get("/api2/json/nodes")
              data = JSON.parse(response.body)
              nodes = data["data"] || []
              
              # Find first online node
              online_node = nodes.find { |n| n["status"] == "online" }
              return online_node["node"] if online_node
              
              # Fallback to first node
              nodes.first&.dig("node") || raise("No available nodes found")
            end

            def find_next_vmid(connection, node)
              # Get all VMs to find next available ID
              vms = []
              
              # Get QEMU VMs
              begin
                response = connection.get("/api2/json/nodes/#{node}/qemu")
                data = JSON.parse(response.body)
                vms.concat(data["data"] || [])
              rescue
                # Ignore errors
              end
              
              # Get LXC containers
              begin
                response = connection.get("/api2/json/nodes/#{node}/lxc")
                data = JSON.parse(response.body)
                vms.concat(data["data"] || [])
              rescue
                # Ignore errors
              end
              
              existing_ids = vms.map { |v| v["vmid"].to_i }.compact
              
              # Find next available ID (start from 100)
              (100..999).each do |id|
                return id.to_s unless existing_ids.include?(id)
              end
              
              raise "No available VM ID found"
            end

            def create_vm_from_template(connection, node, vm_type, vmid, options)
              template = options[:template]
              
              if template
                # Clone from template
                clone_vm_from_template(connection, node, vm_type, vmid, template, options)
              else
                # Create new VM
                create_new_vm(connection, node, vm_type, vmid, options)
              end
            end

            def clone_vm_from_template(connection, node, vm_type, vmid, template, options)
              template_parts = template.ems_ref.split("/")
              template_vmid = template_parts[2]
              template_location = connection.get_vm_location(template_vmid)
              
              # Clone the template
              params = {
                :newid => vmid,
                :name => options[:name] || "vm-#{vmid}",
                :full => options[:full_clone] ? 1 : 0
              }
              
              params[:storage] = options[:storage] if options[:storage]
              params[:target] = node if template_location[:node] != node
              
              response = connection.post("/api2/json/nodes/#{template_location[:node]}/#{template_location[:type]}/#{template_vmid}/clone", params)
              
              if response.status == 200
                # Wait for clone to complete
                wait_for_task(connection, response)
                
                # Configure the new VM - get location after clone
                new_vm_location = connection.get_vm_location(vmid)
                configure_vm(connection, new_vm_location[:node], new_vm_location[:type], vmid, options) if options[:config]
              else
                raise "Failed to clone VM: #{response.body}"
              end
            end

            def create_new_vm(connection, node, vm_type, vmid, options)
              params = {
                :vmid => vmid,
                :name => options[:name] || "vm-#{vmid}"
              }
              
              # Add VM configuration
              params.merge!(options[:config] || {})
              
              response = connection.post("/api2/json/nodes/#{node}/#{vm_type}", params)
              
              if response.status == 200
                # Wait for creation to complete
                wait_for_task(connection, response)
              else
                raise "Failed to create VM: #{response.body}"
              end
            end

            def clone_vm(connection, source_vm, new_vmid, new_name, options)
              source_parts = source_vm.ems_ref.split("/")
              source_vmid = source_parts[2]
              source_location = connection.get_vm_location(source_vmid)
              
              params = {
                :newid => new_vmid,
                :name => new_name,
                :full => options[:full_clone] ? 1 : 0
              }
              
              params[:storage] = options[:storage] if options[:storage]
              params[:target] = options[:node] if options[:node] && options[:node] != source_location[:node]
              
              response = connection.post("/api2/json/nodes/#{source_location[:node]}/#{source_location[:type]}/#{source_vmid}/clone", params)
              
              if response.status == 200
                wait_for_task(connection, response)
                return new_vmid
              else
                raise "Failed to clone VM: #{response.body}"
              end
            end

            def configure_vm(connection, node, vm_type, vmid, options)
              config = options[:config] || {}
              
              # Get current VM location before configuring
              location = connection.get_vm_location(vmid)
              
              # Update VM configuration
              response = connection.put("/api2/json/nodes/#{location[:node]}/#{location[:type]}/#{vmid}/config", config)
              
              unless response.status == 200
                raise "Failed to configure VM: #{response.body}"
              end
            end

            def wait_for_task(connection, response, timeout = 300)
              # Extract task UPID from response
              data = JSON.parse(response.body)
              upid = data["data"]
              
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

