require "json"

module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class RefreshParser
          def self.ems_inv_to_hashes(ems, options = nil)
            new(ems, options).ems_inv_to_hashes
          end

          def initialize(ems, options = nil)
            @ems = ems
            @options = options || {}
            @connection = ems.connect
          end

          def ems_inv_to_hashes
            log_header = "MIQ(#{self.class.name}.#{__method__}) Collecting data for EMS name: [#{@ems.name}] id: [#{@ems.id}]"

            $log.info("#{log_header}...")

            inventory = {
              :vms            => [],
              :hosts           => [],
              :templates       => [],
              :clusters        => [],
              :storages        => [],
              :networks        => [],
              :resource_pools  => []
            }

            begin
              # Get cluster nodes (hosts)
              nodes = get_nodes
              inventory[:hosts] = parse_hosts(nodes)

              # Get VMs and containers
              vms = get_vms
              inventory[:vms] = parse_vms(vms, nodes)

              # Get templates
              templates = get_templates
              inventory[:templates] = parse_templates(templates, nodes)

              # Get storage
              storages = get_storages
              inventory[:storages] = parse_storages(storages, nodes)

              # Get clusters
              clusters = get_clusters
              inventory[:clusters] = parse_clusters(clusters)

              # Get networks
              networks = get_networks
              inventory[:networks] = parse_networks(networks)

            rescue => err
              $log.error("#{log_header} Error: #{err.class.name}: #{err}")
              $log.error("#{log_header} #{err.backtrace.join("\n")}")
              raise
            end

            $log.info("#{log_header}...Complete")

            inventory
          end

          private

          def get_nodes
            response = @connection.get("/api2/json/nodes")
            data = JSON.parse(response.body)
            data["data"] || []
          end

          def get_vms
            vms = []
            nodes = get_nodes

            nodes.each do |node|
              # Get QEMU VMs
              begin
                response = @connection.get("/api2/json/nodes/#{node['node']}/qemu")
                data = JSON.parse(response.body)
                qemu_vms = data["data"] || []
                qemu_vms.each do |vm|
                  vm["type"] = "qemu"
                  vm["node"] = node["node"]
                  vms << vm
                end
              rescue => e
                $log.warn("Failed to get QEMU VMs from node #{node['node']}: #{e.message}")
              end

              # Get LXC containers
              begin
                response = @connection.get("/api2/json/nodes/#{node['node']}/lxc")
                data = JSON.parse(response.body)
                lxc_vms = data["data"] || []
                lxc_vms.each do |vm|
                  vm["type"] = "lxc"
                  vm["node"] = node["node"]
                  vms << vm
                end
              rescue => e
                $log.warn("Failed to get LXC containers from node #{node['node']}: #{e.message}")
              end
            end

            vms
          end

          def get_templates
            templates = []
            nodes = get_nodes

            nodes.each do |node|
              # Get QEMU templates
              begin
                response = @connection.get("/api2/json/nodes/#{node['node']}/qemu")
                data = JSON.parse(response.body)
                qemu_templates = (data["data"] || []).select { |t| t["template"] == 1 }
                qemu_templates.each do |template|
                  template["type"] = "qemu"
                  template["node"] = node["node"]
                  templates << template
                end
              rescue => e
                $log.warn("Failed to get QEMU templates from node #{node['node']}: #{e.message}")
              end

              # Get LXC templates
              begin
                response = @connection.get("/api2/json/nodes/#{node['node']}/lxc")
                data = JSON.parse(response.body)
                lxc_templates = (data["data"] || []).select { |t| t["template"] == 1 }
                lxc_templates.each do |template|
                  template["type"] = "lxc"
                  template["node"] = node["node"]
                  templates << template
                end
              rescue => e
                $log.warn("Failed to get LXC templates from node #{node['node']}: #{e.message}")
              end
            end

            templates
          end

          def get_storages
            storages = []
            nodes = get_nodes

            nodes.each do |node|
              begin
                response = @connection.get("/api2/json/nodes/#{node['node']}/storage")
                data = JSON.parse(response.body)
                node_storages = data["data"] || []
                node_storages.each do |storage|
                  storage["node"] = node["node"]
                  storages << storage
                end
              rescue => e
                $log.warn("Failed to get storage from node #{node['node']}: #{e.message}")
              end
            end

            storages.uniq { |s| s["storage"] }
          end

          def get_clusters
            begin
              response = @connection.get("/api2/json/cluster/status")
              data = JSON.parse(response.body)
              data["data"] || []
            rescue => e
              $log.warn("Failed to get cluster status: #{e.message}")
              []
            end
          end

          def parse_hosts(nodes)
            nodes.map do |node|
              {
                :type          => "ManageIQ::Providers::Proxmox::InfraManager::Host",
                :ems_ref       => node["node"],
                :name          => node["node"],
                :hostname      => node["node"],
                :ipaddress     => node["ip"] || node["node"],
                :vmm_vendor    => "proxmox",
                :vmm_version   => node["pveversion"] || "unknown",
                :vmm_product   => "Proxmox VE",
                :power_state   => node["status"] == "online" ? "on" : "off",
                :connection_state => node["status"] == "online" ? "connected" : "disconnected"
              }
            end
          end

          def parse_vms(vms, nodes)
            vms.map do |vm|
              node_name = vm["node"]
              vmid = vm["vmid"].to_s
              vm_type = vm["type"] || "qemu"

              {
                :type          => "ManageIQ::Providers::Proxmox::InfraManager::Vm",
                :ems_ref       => "#{node_name}/#{vm_type}/#{vmid}",
                :name          => vm["name"] || "VM #{vmid}",
                :description   => vm["name"] || "",
                :vendor        => "proxmox",
                :location      => "#{node_name}/#{vm_type}/#{vmid}",
                :template      => false,
                :raw_power_state => vm["status"] || "unknown",
                :host          => {
                  :ems_ref => node_name
                },
                :hardware      => {
                  :cpu_total_cores => vm["cpus"] || 1,
                  :memory_mb       => (vm["maxmem"] || 0) / (1024 * 1024),
                  :disk_capacity   => (vm["maxdisk"] || 0) / (1024 * 1024 * 1024) # Convert to GB
                },
                :operating_system => {
                  :product_name => vm["ostype"] || "Unknown"
                }
              }
            end
          end

          def parse_templates(templates, nodes)
            templates.map do |template|
              node_name = template["node"]
              vmid = template["vmid"].to_s
              template_type = template["type"] || "qemu"

              {
                :type          => "ManageIQ::Providers::Proxmox::InfraManager::Template",
                :ems_ref       => "#{node_name}/#{template_type}/#{vmid}",
                :name          => template["name"] || "Template #{vmid}",
                :description   => template["name"] || "",
                :vendor        => "proxmox",
                :location      => "#{node_name}/#{template_type}/#{vmid}",
                :template      => true,
                :host          => {
                  :ems_ref => node_name
                },
                :hardware      => {
                  :cpu_total_cores => template["cpus"] || 1,
                  :memory_mb       => (template["maxmem"] || 0) / (1024 * 1024),
                  :disk_capacity   => (template["maxdisk"] || 0) / (1024 * 1024 * 1024)
                }
              }
            end
          end

          def parse_storages(storages, nodes)
            storages.map do |storage|
              {
                :type          => "ManageIQ::Providers::Proxmox::InfraManager::Storage",
                :ems_ref       => storage["storage"],
                :name          => storage["storage"],
                :store_type    => storage["type"] || "unknown",
                :total_space   => (storage["total"] || 0) * 1024 * 1024, # Convert to bytes
                :free_space    => (storage["avail"] || 0) * 1024 * 1024,
                :storage_domain_type => storage["type"] || "unknown"
              }
            end
          end

          def parse_clusters(cluster_data)
            # Proxmox clusters are typically single cluster per EMS
            # Extract cluster information from cluster status
            cluster_name = @ems.name # Use EMS name as cluster name
            {
              :type          => "ManageIQ::Providers::Proxmox::InfraManager::Cluster",
              :ems_ref       => cluster_name,
              :name          => cluster_name,
              :uid_ems       => cluster_name
            }
          end

          def get_networks
            networks = []
            nodes = get_nodes

            nodes.each do |node|
              begin
                response = @connection.get("/api2/json/nodes/#{node['node']}/network")
                data = JSON.parse(response.body)
                node_networks = data["data"] || []
                node_networks.each do |network|
                  network["node"] = node["node"]
                  networks << network
                end
              rescue => e
                $log.warn("Failed to get networks from node #{node['node']}: #{e.message}")
              end
            end

            networks
          end

          def parse_networks(networks)
            networks.map do |network|
              {
                :type          => "ManageIQ::Providers::Proxmox::InfraManager::Network",
                :ems_ref       => "#{network['node']}/#{network['iface'] || network['interface']}",
                :name          => network["iface"] || network["interface"] || "unknown",
                :description   => network["type"] || "network",
                :host          => {
                  :ems_ref => network["node"]
                }
              }
            end
          end
        end
      end
    end
  end
end

