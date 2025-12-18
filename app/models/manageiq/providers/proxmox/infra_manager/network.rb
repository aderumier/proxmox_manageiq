module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class Network < ManageIQ::Providers::InfraManager::Network
          def self.display_name(number = 1)
            n_("Network (Proxmox)", "Networks (Proxmox)", number)
          end

          def self.refresh_network(ems, target = nil)
            # Refresh network information from Proxmox
            # This would collect network interfaces from nodes
            ems.with_provider_connection do |connection|
              nodes = get_nodes(connection)
              networks = []
              
              nodes.each do |node|
                node_networks = get_node_networks(connection, node["node"])
                networks.concat(node_networks)
              end
              
              networks
            end
          end

          private

          def self.get_nodes(connection)
            response = connection.get("/api2/json/nodes")
            data = JSON.parse(response.body)
            data["data"] || []
          end

          def self.get_node_networks(connection, node)
            networks = []
            
            begin
              # Get network interfaces from node
              response = connection.get("/api2/json/nodes/#{node}/network")
              data = JSON.parse(response.body)
              interfaces = data["data"] || []
              
              interfaces.each do |interface|
                networks << {
                  :name => interface["iface"] || interface["interface"],
                  :type => interface["type"] || "bridge",
                  :node => node,
                  :address => interface["address"],
                  :netmask => interface["netmask"],
                  :gateway => interface["gateway"]
                }
              end
            rescue => e
              $log.warn("Failed to get networks from node #{node}: #{e.message}")
            end
            
            networks
          end
        end
      end
    end
  end
end

