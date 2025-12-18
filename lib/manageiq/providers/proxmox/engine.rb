module ManageIQ
  module Providers
    module Proxmox
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Proxmox

        config.autoload_paths << root.join("lib").to_s

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _("Proxmox Provider")
        end
      end
    end
  end
end

