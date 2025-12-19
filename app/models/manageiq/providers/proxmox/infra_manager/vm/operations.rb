module ManageIQ
  module Providers
    module Proxmox
      class InfraManager
        class Vm
          module Operations
            extend ActiveSupport::Concern

            included do
              supports :start do
                unsupported_reason_add(:start, _("The VM is not connected to a host")) if host.nil?
                unsupported_reason_add(:start, _("The VM is already powered on")) if current_state == "on"
              end

              supports :stop do
                unsupported_reason_add(:stop, _("The VM is not connected to a host")) if host.nil?
                unsupported_reason_add(:stop, _("The VM is already powered off")) if current_state == "off"
              end

              supports :suspend do
                unsupported_reason_add(:suspend, _("The VM is not connected to a host")) if host.nil?
                unsupported_reason_add(:suspend, _("The VM is not powered on")) unless current_state == "on"
              end

              supports :shutdown_guest do
                unsupported_reason_add(:shutdown_guest, _("The VM is not connected to a host")) if host.nil?
                unsupported_reason_add(:shutdown_guest, _("The VM is not powered on")) unless current_state == "on"
              end

              supports :reboot_guest do
                unsupported_reason_add(:reboot_guest, _("The VM is not connected to a host")) if host.nil?
                unsupported_reason_add(:reboot_guest, _("The VM is not powered on")) unless current_state == "on"
              end
            end

            def raw_start
              ext_management_system.with_provider_connection do |connection|
                vmid = ems_ref.split("/").last
                location = connection.get_vm_location(vmid)
                connection.post("/api2/json/nodes/#{location[:node]}/#{location[:type]}/#{vmid}/status/start")
              end
            end

            def raw_stop
              ext_management_system.with_provider_connection do |connection|
                vmid = ems_ref.split("/").last
                location = connection.get_vm_location(vmid)
                connection.post("/api2/json/nodes/#{location[:node]}/#{location[:type]}/#{vmid}/status/stop")
              end
            end

            def raw_suspend
              ext_management_system.with_provider_connection do |connection|
                vmid = ems_ref.split("/").last
                location = connection.get_vm_location(vmid)
                connection.post("/api2/json/nodes/#{location[:node]}/#{location[:type]}/#{vmid}/status/suspend")
              end
            end

            def raw_shutdown_guest
              ext_management_system.with_provider_connection do |connection|
                vmid = ems_ref.split("/").last
                location = connection.get_vm_location(vmid)
                connection.post("/api2/json/nodes/#{location[:node]}/#{location[:type]}/#{vmid}/status/shutdown")
              end
            end

            def raw_reboot_guest
              ext_management_system.with_provider_connection do |connection|
                vmid = ems_ref.split("/").last
                location = connection.get_vm_location(vmid)
                connection.post("/api2/json/nodes/#{location[:node]}/#{location[:type]}/#{vmid}/status/reboot")
              end
            end
          end
        end
      end
    end
  end
end

