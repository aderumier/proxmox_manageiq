# Usage Guide

This guide provides practical examples for using the Proxmox VE provider in ManageIQ.

## Adding a Proxmox Provider

### Via UI

1. Navigate to **Compute > Infrastructure > Providers**
2. Click **Configuration > Add a New Infrastructure Provider**
3. Select **Proxmox VE**
4. Fill in the required fields:
   - **Name**: `My Proxmox Cluster`
   - **Hostname**: `192.168.1.100` (or your Proxmox server IP)
   - **Port**: `8006`
   - **Username**: `root@pam` (or your Proxmox username)
   - **Password**: Your Proxmox password
5. Click **Validate** to test the connection
6. Click **Add** to save

### Via Rails Console

```ruby
ems = ManageIQ::Providers::Proxmox::InfraManager.create(
  :name     => "My Proxmox Cluster",
  :hostname => "192.168.1.100",
  :port     => 8006
)

ems.update_authentication(
  :default => {
    :userid   => "root@pam",
    :password => "your-password"
  }
)

ems.verify_credentials
```

## Refreshing Inventory

### Via UI

1. Navigate to your provider
2. Click **Configuration > Refresh Relationships and Power States**
3. Wait for the refresh to complete

### Via Rails Console

```ruby
ems = ManageIQ::Providers::Proxmox::InfraManager.find_by(:name => "My Proxmox Cluster")
EmsRefresh.queue_refresh(ems)
```

## Managing VMs

### Starting a VM

```ruby
vm = ManageIQ::Providers::Proxmox::InfraManager::Vm.find_by(:name => "my-vm")
vm.start
```

### Stopping a VM

```ruby
vm.stop
```

### Getting VM Status

```ruby
vm.power_state  # => "on" or "off"
vm.raw_power_state  # => "running" or "stopped"
```

## Querying Inventory

### List All VMs

```ruby
ManageIQ::Providers::Proxmox::InfraManager::Vm.all
```

### List All Hosts

```ruby
ManageIQ::Providers::Proxmox::InfraManager::Host.all
```

### List All Storage

```ruby
ManageIQ::Providers::Proxmox::InfraManager::Storage.all
```

## Direct API Access

You can also access the Proxmox API directly through the connection:

```ruby
ems = ManageIQ::Providers::Proxmox::InfraManager.first
ems.with_provider_connection do |connection|
  # Get all nodes
  response = connection.get("/api2/json/nodes")
  nodes = JSON.parse(response.body)["data"]
  
  # Get VMs on a specific node
  response = connection.get("/api2/json/nodes/node1/qemu")
  vms = JSON.parse(response.body)["data"]
end
```

## Troubleshooting

### Connection Issues

If you're having trouble connecting:

1. **Check network connectivity**: Ensure ManageIQ can reach the Proxmox server on port 8006
2. **Verify credentials**: Test with `ems.verify_credentials` in Rails console
3. **Check SSL certificates**: The provider disables SSL verification by default for self-signed certificates
4. **Review logs**: Check ManageIQ logs for detailed error messages

### Refresh Issues

If inventory isn't refreshing:

1. **Check provider status**: Ensure the provider is enabled
2. **Review refresh worker**: Check if refresh workers are running
3. **Check API access**: Verify the Proxmox API is accessible
4. **Review logs**: Check for API errors in the logs

### VM Operation Issues

If VM operations are failing:

1. **Check VM state**: Ensure the VM is in the correct state for the operation
2. **Verify permissions**: Ensure the Proxmox user has permissions for the operation
3. **Check API response**: Review the API response for error messages
4. **Review logs**: Check ManageIQ logs for detailed error information

## Examples

### Bulk VM Operations

```ruby
vms = ManageIQ::Providers::Proxmox::InfraManager::Vm.where(:power_state => "on")
vms.each do |vm|
  puts "Stopping #{vm.name}..."
  vm.stop
end
```

### Finding VMs by Host

```ruby
host = ManageIQ::Providers::Proxmox::InfraManager::Host.find_by(:name => "node1")
vms = host.vms
```

### Getting Storage Usage

```ruby
storage = ManageIQ::Providers::Proxmox::InfraManager::Storage.find_by(:name => "local")
puts "Total: #{storage.total_space / 1.gigabyte} GB"
puts "Free: #{storage.free_space / 1.gigabyte} GB"
puts "Used: #{storage.used_space / 1.gigabyte} GB"
```

