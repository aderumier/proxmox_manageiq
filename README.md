# ManageIQ::Providers::Proxmox

[![CI](https://github.com/ManageIQ/manageiq-providers-proxmox/workflows/CI/badge.svg)](https://github.com/ManageIQ/manageiq-providers-proxmox/actions)
[![Maintainability](https://api.codeclimate.com/v1/badges/xxx/maintainability)](https://codeclimate.com/github/ManageIQ/manageiq-providers-proxmox)
[![Test Coverage](https://api.codeclimate.com/v1/badges/xxx/test_coverage)](https://codeclimate.com/github/ManageIQ/manageiq-providers-proxmox)

ManageIQ plugin for the Proxmox VE provider.

## Features

- **Inventory Collection**: Automatically discovers and manages Proxmox VE resources
  - Virtual Machines (QEMU/KVM)
  - LXC Containers
  - Hosts (Proxmox nodes)
  - Storage pools
  - Templates
  - Clusters

- **VM Operations**: Full lifecycle management
  - Start/Stop VMs
  - Suspend/Resume
  - Reboot
  - Graceful shutdown

- **Event Monitoring**: Track changes and events in your Proxmox environment

- **Metrics Collection**: Framework for collecting performance metrics

## Requirements

- ManageIQ core application
- Proxmox VE 6.0 or later
- Ruby 2.7+

## Installation

Add this line to your ManageIQ application's Gemfile:

```ruby
gem 'manageiq-providers-proxmox'
```

And then execute:

```bash
bundle install
```

## Configuration

1. In ManageIQ, navigate to **Compute > Infrastructure > Providers**
2. Click **Configuration > Add a New Infrastructure Provider**
3. Select **Proxmox VE** as the provider type
4. Enter your Proxmox server details:
   - **Name**: A descriptive name for this provider
   - **Hostname**: IP address or hostname of your Proxmox server
   - **Port**: 8006 (default)
   - **Username**: Proxmox username (e.g., `root@pam`)
   - **Password**: Proxmox password

5. Click **Validate** to verify the connection
6. Click **Add** to save the provider

## Development

See the section on plugins in the [ManageIQ Developer Setup](https://github.com/ManageIQ/guides/blob/master/developer_setup/plugins.md)

For quick local setup run `bin/setup`, which will clone the core ManageIQ repository under the _spec_ directory and setup necessary config files. If you have already cloned it, you can run `bin/update` to bring the core ManageIQ code up to date.

### Running Tests

```bash
bundle exec rspec
```

### Code Style

This project follows the ManageIQ style guide. Run RuboCop to check style:

```bash
bundle exec rubocop
```

## API Documentation

The provider uses the [Proxmox VE API](https://pve.proxmox.com/pve-docs/api-viewer/index.html) to interact with Proxmox servers.

### Authentication

The provider uses ticket-based authentication:
1. Authenticates with username/password to get a ticket
2. Uses the ticket as a cookie for subsequent requests
3. Includes CSRF token for state-changing operations

### Supported Endpoints

- `/api2/json/access/ticket` - Authentication
- `/api2/json/nodes` - List cluster nodes
- `/api2/json/nodes/{node}/qemu` - List QEMU VMs
- `/api2/json/nodes/{node}/lxc` - List LXC containers
- `/api2/json/nodes/{node}/storage` - List storage pools
- `/api2/json/cluster/status` - Cluster status
- `/api2/json/nodes/{node}/qemu/{vmid}/status/{action}` - VM operations

## Known Limitations

- Event monitoring uses polling (Proxmox doesn't provide native event streams)
- Metrics collection framework is in place but needs implementation
- SSL certificate verification is disabled for self-signed certificates

See [IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md) for more details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## References

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/index.html)
- [ManageIQ Provider Development Guide](https://www.manageiq.org/docs/guides/providers/writing_a_new_provider)
- [oVirt Provider Reference](https://github.com/ManageIQ/manageiq-providers-ovirt)

