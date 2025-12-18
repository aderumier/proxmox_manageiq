# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial implementation of Proxmox VE provider for ManageIQ
- Support for inventory collection (VMs, Hosts, Templates, Storage, Clusters, Networks)
- Support for VM operations (start, stop, suspend, reboot, shutdown)
- Connection and authentication to Proxmox VE API
- Refresh workers and event monitoring framework
- Complete metrics collection implementation
- VM provisioning (create, clone from template)
- Snapshot management (create, delete, revert)
- Network discovery and management
- Improved event monitoring with UPID tracking
- Integration tests with VCR support
- Comprehensive test coverage

