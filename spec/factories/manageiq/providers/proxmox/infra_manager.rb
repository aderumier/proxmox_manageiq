FactoryBot.define do
  factory :ems_proxmox_infra, :class => "ManageIQ::Providers::Proxmox::InfraManager", :parent => :ems_infra do
    trait :with_authentication do
      after(:create) do |ems|
        ems.authentications << FactoryBot.create(:authentication, :userid => "root", :password => "password")
      end
    end
  end

  factory :vm_proxmox, :class => "ManageIQ::Providers::Proxmox::InfraManager::Vm", :parent => :vm_infra do
    vendor { "proxmox" }
  end

  factory :host_proxmox, :class => "ManageIQ::Providers::Proxmox::InfraManager::Host", :parent => :host_infra do
    vendor { "proxmox" }
  end

  factory :template_proxmox, :class => "ManageIQ::Providers::Proxmox::InfraManager::Template", :parent => :template_infra do
    vendor { "proxmox" }
  end
end

