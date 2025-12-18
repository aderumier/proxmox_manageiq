require "json"

module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class MetricsCollectorWorker
          class Runner < ManageIQ::Providers::BaseManager::MetricsCollectorWorker::Runner
            def collect_metrics
              target.ems_refs.each do |ems_ref|
                collect_metrics_for_target(ems_ref)
              end
            end

            def collect_metrics_for_target(ems_ref)
              vm = Vm.find_by(:ems_ref => ems_ref)
              return unless vm

              ext_management_system.with_provider_connection do |connection|
                collect_vm_metrics(vm, connection)
              end
            rescue => err
              _log.error("Error collecting metrics for #{ems_ref}: #{err.class.name}: #{err}")
              _log.error(err.backtrace.join("\n"))
            end

            private

            def collect_vm_metrics(vm, connection)
              parts = vm.ems_ref.split("/")
              return unless parts.length >= 3

              node = parts[0]
              vm_type = parts[1] # qemu or lxc
              vmid = parts[2]

              # Get current VM status with metrics
              response = connection.get("/api2/json/nodes/#{node}/#{vm_type}/#{vmid}/status/current")
              data = JSON.parse(response.body)["data"]

              # Get VM configuration for max values
              config_response = connection.get("/api2/json/nodes/#{node}/#{vm_type}/#{vmid}/config")
              config = JSON.parse(config_response.body)["data"]

              # Calculate metrics
              metrics = {
                :timestamp => Time.now.utc,
                :cpu_usage_rate_average => calculate_cpu_usage(data),
                :mem_usage_absolute_average => calculate_memory_usage(data, config),
                :disk_usage_rate_average => calculate_disk_usage(data, config),
                :net_usage_rate_average => calculate_network_usage(data)
              }

              # Store metrics (this would typically use ManageIQ's metrics storage)
              store_metrics(vm, metrics)
            end

            def calculate_cpu_usage(data)
              # CPU usage is in percentage (0-100)
              cpu = data["cpu"] || 0.0
              cpu * 100.0 # Convert to percentage
            end

            def calculate_memory_usage(data, config)
              # Memory usage percentage
              used = data["mem"] || 0
              max = data["maxmem"] || config["memory"] || 1
              return 0.0 if max.zero?

              (used.to_f / max.to_f) * 100.0
            end

            def calculate_disk_usage(data, config)
              # Disk usage percentage
              used = data["disk"] || 0
              max = data["maxdisk"] || config["disk"] || 1
              return 0.0 if max.zero?

              (used.to_f / max.to_f) * 100.0
            end

            def calculate_network_usage(data)
              # Network usage in bytes per second
              # This is a simplified calculation
              netin = data["netin"] || 0
              netout = data["netout"] || 0
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

