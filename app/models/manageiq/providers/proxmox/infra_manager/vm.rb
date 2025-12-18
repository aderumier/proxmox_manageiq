module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class Vm < ManageIQ::Providers::InfraManager::Vm
          include_concern "Operations"
          include_concern "Provision"
          include_concern "Snapshots"

          def self.calculate_power_state(raw_power_state)
            case raw_power_state.to_s.downcase
            when "running"
              "on"
            when "stopped"
              "off"
            else
              "unknown"
            end
          end

          def self.display_name(number = 1)
            n_("Virtual Machine (Proxmox)", "Virtual Machines (Proxmox)", number)
          end

          def provider_object(connection = nil)
            connection ||= ext_management_system.connect
            # Get VM details from Proxmox
            vmid = ems_ref.split("/").last
            node = ems_ref.split("/")[0]
            connection.get("/api2/json/nodes/#{node}/#{type_path}/#{vmid}")
          end

          def type_path
            # Determine if this is a QEMU VM or LXC container
            # This should be stored in the VM model or determined from API
            "qemu" # Default to QEMU, should be configurable
          end

          def raw_start
            with_provider_object do |vm|
              vmid = ems_ref.split("/").last
              node = ems_ref.split("/")[0]
              ext_management_system.connect.post("/api2/json/nodes/#{node}/#{type_path}/#{vmid}/status/start")
            end
            update_attributes!(:raw_power_state => "running")
          end

          def raw_stop
            with_provider_object do |vm|
              vmid = ems_ref.split("/").last
              node = ems_ref.split("/")[0]
              ext_management_system.connect.post("/api2/json/nodes/#{node}/#{type_path}/#{vmid}/status/stop")
            end
            update_attributes!(:raw_power_state => "stopped")
          end

          def raw_suspend
            with_provider_object do |vm|
              vmid = ems_ref.split("/").last
              node = ems_ref.split("/")[0]
              ext_management_system.connect.post("/api2/json/nodes/#{node}/#{type_path}/#{vmid}/status/suspend")
            end
            update_attributes!(:raw_power_state => "suspended")
          end

          def raw_reset
            with_provider_object do |vm|
              vmid = ems_ref.split("/").last
              node = ems_ref.split("/")[0]
              ext_management_system.connect.post("/api2/json/nodes/#{node}/#{type_path}/#{vmid}/status/reset")
            end
          end

          def raw_shutdown_guest
            with_provider_object do |vm|
              vmid = ems_ref.split("/").last
              node = ems_ref.split("/")[0]
              ext_management_system.connect.post("/api2/json/nodes/#{node}/#{type_path}/#{vmid}/status/shutdown")
            end
          end

          def raw_reboot_guest
            with_provider_object do |vm|
              vmid = ems_ref.split("/").last
              node = ems_ref.split("/")[0]
              ext_management_system.connect.post("/api2/json/nodes/#{node}/#{type_path}/#{vmid}/status/reboot")
            end
          end

          def with_provider_object
            ext_management_system.with_provider_connection do |connection|
              yield(connection)
            end
          end

          def with_provider_connection
            ext_management_system.with_provider_connection do |connection|
              yield(connection)
            end
          end
        end
      end
    end
  end
end

