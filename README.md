# GacBoost Steering v1.7.4

A KernelSU module for managing sing-box configuration and traffic steering.

## Features

- **Traffic Steering**: Manage target apps and traffic routing rules
- **sing-box Integration**: Control sing-box proxy configurations
- **Configuration Management**: Override and default configuration support
- **Web UI Support**: KernelSU manager integration
- **Secure Execution**: Root-only runtime directory with proper permissions

## Installation

This module is designed to work with KernelSU. Install it through the KernelSU manager.

## Configuration

- **Config File**: `/data/adb/gacboost-steering/config.conf`
- **Override File**: `/data/adb/gacboost-steering/override.conf`
- **Runtime Directory**: `/data/adb/gacboost-steering/run`

## Scripts

- `boot-completed.sh` - Daemon script for managing the module
- `action.sh` - Action button handler in KernelSU manager (read-only status)
- `apply.sh` - Configuration reload entry point
- `customize.sh` - Installation setup script
- `uninstall.sh` - Cleanup and uninstallation script

## Version History

### v1.7.4
- Runtime path moved to `/data/adb/gacboost-steering/run`
- sing-box only displays module's own processes
- Exit check uses `/proc/net/tcp`
- TARGETS uses three-level priority system
- v1.6 legacy directory cleanup
