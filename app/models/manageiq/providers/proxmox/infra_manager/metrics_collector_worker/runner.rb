require "json"

module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class MetricsCollectorWorker
          class Runner < ManageIQ::Providers::BaseManager::MetricsCollectorWorker::Runner
            def collect_metrics
              ext_management_system.with_provider_connection do |connection|
                # Get all VM resources with stats in a single API call
                response = connection.get("/api2/json/cluster/resources")
                data = JSON.parse(response.body)
                resources = data["data"] || []
                
                # Filter to only VMs (qemu and lxc)
                vm_resources = resources.select { |r| r["type"] == "qemu" || r["type"] == "lxc" }
                
                # Create a hash mapping vmid to resource data for quick lookup
                resources_by_vmid = {}
                vm_resources.each do |resource|
                  vmid = resource["vmid"]
                  resources_by_vmid[vmid] = resource if vmid
                end
                
                # Collect metrics for all target VMs
                target.ems_refs.each do |ems_ref|
                  collect_metrics_for_target(ems_ref, resources_by_vmid)
                end
              end
            rescue => err
              _log.error("Error collecting metrics: #{err.class.name}: #{err}")
              _log.error(err.backtrace.join("\n"))
            end

            def collect_metrics_for_target(ems_ref, resources_by_vmid)
              vm = Vm.find_by(:ems_ref => ems_ref)
              return unless vm

              parts = vm.ems_ref.split("/")
              return unless parts.length >= 3

              vmid = parts[2].to_i
              resource_data = resources_by_vmid[vmid]
              
              unless resource_data
                _log.warn("VM #{vmid} not found in cluster resources")
                return
              end

              # Calculate metrics from resource data
              metrics = {
                :timestamp => Time.now.utc,
                :cpu_usage_rate_average => calculate_cpu_usage(resource_data),
                :mem_usage_absolute_average => calculate_memory_usage(resource_data),
                :disk_usage_rate_average => calculate_disk_usage(resource_data),
                :net_usage_rate_average => calculate_network_usage(resource_data)
              }

              # Store metrics
              store_metrics(vm, metrics)
            rescue => err
              _log.error("Error collecting metrics for #{ems_ref}: #{err.class.name}: #{err}")
              _log.error(err.backtrace.join("\n"))
            end

            private

            def calculate_cpu_usage(resource_data)
              # CPU usage from cluster/resources - cpu is already a percentage (0-1)
              cpu = resource_data["cpu"] || 0.0
              cpu * 100.0 # Convert to percentage
            end

            def calculate_memory_usage(resource_data)
              # Memory usage percentage from cluster/resources
              used = resource_data["mem"] || 0
              max = resource_data["maxmem"] || 1
              return 0.0 if max.zero?

              (used.to_f / max.to_f) * 100.0
            end

            def calculate_disk_usage(resource_data)
              # Disk usage percentage from cluster/resources
              used = resource_data["disk"] || 0
              max = resource_data["maxdisk"] || 1
              return 0.0 if max.zero?

              (used.to_f / max.to_f) * 100.0
            end

            def calculate_network_usage(resource_data)
              # Network usage in bytes per second from cluster/resources
              # Note: cluster/resources may not have netin/netout, use netin/netout if available
              netin = resource_data["netin"] || 0
              netout = resource_data["netout"] || 0
              # Return total network usage
              netin + netout
            end

            def store_metrics(vm, metrics)
              # Store metrics using ManageIQ's metrics system
              require "manageiq/providers/base_manager/metrics_collector"
              
              # Create metric records
              metric_data = {
                :timestamp => metrics[:timestamp],
                :cpu_usage_rate_average => metrics[:cpu_usage_rate_average],
                :mem_usage_absolute_average => metrics[:mem_usage_absolute_average],
                :disk_usage_rate_average => metrics[:disk_usage_rate_average],
                :net_usage_rate_average => metrics[:net_usage_rate_average]
              }
              
              # Use ManageIQ's metric collection system
              vm.metrics.create!(metric_data) if vm.respond_to?(:metrics)
              
              _log.debug("Stored metrics for #{vm.name}: CPU=#{metrics[:cpu_usage_rate_average]}%, Memory=#{metrics[:mem_usage_absolute_average]}%")
            rescue => err
              _log.error("Error storing metrics for #{vm.name}: #{err.class.name}: #{err}")
            end
          end
        end
      end
    end
  end
end

