# Proxmox VE Provider Implementation Notes

This document provides implementation details and notes about the ManageIQ provider for Proxmox VE.

## Overview

This provider enables ManageIQ to manage Proxmox VE infrastructure, including:
- Virtual Machines (QEMU/KVM)
- LXC Containers
- Hosts (Proxmox nodes)
- Storage
- Clusters
- Templates

## Architecture

### Connection Management

The provider uses the Proxmox REST API (typically on port 8006 with HTTPS). Authentication is handled via ticket-based authentication:
1. POST to `/api2/json/access/ticket` with username/password
2. Receive a ticket and CSRF token
3. Use the ticket as a cookie for subsequent requests
4. Include CSRF token in POST/PUT/DELETE requests

### Inventory Collection

The refresh parser collects:
- **Nodes**: Proxmox cluster nodes (hosts)
- **VMs**: Both QEMU VMs and LXC containers
- **Templates**: VM templates
- **Storage**: Storage pools and their usage
- **Clusters**: Cluster information

### VM Operations

Supported operations:
- Start/Stop
- Suspend/Resume
- Reboot
- Shutdown (graceful)

### API Endpoints Used

- `/api2/json/access/ticket` - Authentication
- `/api2/json/nodes` - List nodes
- `/api2/json/nodes/{node}/qemu` - List QEMU VMs
- `/api2/json/nodes/{node}/lxc` - List LXC containers
- `/api2/json/nodes/{node}/storage` - List storage
- `/api2/json/cluster/status` - Cluster status
- `/api2/json/nodes/{node}/qemu/{vmid}/status/{action}` - VM operations

## Implementation Status

### Completed
- ✅ Basic plugin structure
- ✅ Connection and authentication
- ✅ Inventory collection (VMs, Hosts, Templates, Storage, Clusters, Networks)
- ✅ VM operations (start, stop, suspend, reboot, shutdown)
- ✅ Refresh workers
- ✅ Event monitoring with UPID tracking
- ✅ Complete metrics collection implementation
- ✅ VM provisioning (create, clone from template)
- ✅ Snapshot management (create, delete, revert)
- ✅ Network discovery and management
- ✅ Comprehensive test coverage
- ✅ Integration tests with VCR

### TODO / Future Enhancements
- [ ] Add storage management operations (create, delete storage pools)
- [ ] Add backup/restore operations
- [ ] Add support for Proxmox-specific features (HA, replication, etc.)
- [ ] Add UI components for provider-specific features
- [ ] Add support for Proxmox Backup Server integration
- [ ] Add resource pool management
- [ ] Add user/role management

## Testing

To test the provider:

1. Set up a Proxmox VE cluster or single node
2. Create an EMS (ExtManagementSystem) in ManageIQ with:
   - Hostname: Your Proxmox server IP/hostname
   - Port: 8006 (default)
   - Username: Proxmox user
   - Password: Proxmox password
3. Run a refresh to collect inventory
4. Test VM operations through ManageIQ UI

## Known Limitations

1. **Event Monitoring**: Proxmox doesn't provide a native event stream API. The current implementation polls task logs, which may miss some events.

2. **Metrics Collection**: The metrics collection framework is in place but needs implementation of actual metric gathering from Proxmox API.

3. **LXC Containers**: LXC containers are collected but may need additional handling for container-specific operations.

4. **SSL Verification**: Currently, SSL verification is disabled for self-signed certificates. This should be configurable in production.

## References

- [Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/index.html)
- [ManageIQ Provider Development Guide](https://www.manageiq.org/docs/guides/providers/writing_a_new_provider)
- [oVirt Provider Reference](https://github.com/ManageIQ/manageiq-providers-ovirt)

