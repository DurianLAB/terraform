# LXC K3s Terraform Configuration

[![Website](https://img.shields.io/website?url=https%3A%2F%2Fdurianlab.tech)](https://durianlab.tech)
[![GitHub issues](https://img.shields.io/github/issues/DurianLAB/terraform.svg)](https://github.com/DurianLAB/terraform/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/DurianLAB/terraform.svg)](https://github.com/DurianLAB/terraform/pulls)
[![License: Custom](https://img.shields.io/badge/License-Custom%20Non--Commercial-blue.svg)](https://github.com/DurianLAB/terraform/blob/main/LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/DurianLAB/terraform.svg)](https://github.com/DurianLAB/terraform/commits/main)

This repository contains Terraform configurations for deploying K3s clusters in LXD virtual machines with flexible networking options (bridge or macvlan).

## Architecture Diagrams

The system architecture is documented in [docs/diagram.md](docs/diagram.md), which includes:
- Deployment flow diagrams
- SysML block definition diagrams
- Mermaid flowchart
- Connection sequence diagrams
- Component requirements
- Jenkins pipeline example

To view the Mermaid diagram, use a Markdown viewer that supports Mermaid (VS Code with extension, GitHub, etc.).

## License

This project is licensed under a Custom Non-Commercial License - see the [LICENSE](LICENSE) file for details. This license allows free sharing and modification for non-commercial use but prohibits commercial sale or commercial exploitation.

Developed by [DurianLAB](https://durianlab.tech/).

## Repository Structure

```
├── module/
│   └── lxc-k3s-vm/              # Shared module for LXC K3s VM
├── scenarios/                   # Legacy scenario configurations (deprecated)
│   ├── bridge-networking/
│   └── macvlan-networking/
├── start-here.sh               # Idempotent wrapper script
├── test-macvlan-*.sh            # Connectivity testing scripts
├── TROUBLESHOOTING.md           # Network configuration troubleshooting
└── README.md                    # This file
```

## Networking Options

The configuration supports two network types via the `network_type` variable:

### Bridge Networking
- **Use Case**: Development and testing environments
- **Network Type**: LXD bridge with NAT
- **Host Access**: Direct communication with VMs
- **External Access**: Requires port forwarding
- **IP Range**: Isolated subnet (10.150.x.x)

### Macvlan Networking
- **Use Case**: Production deployments
- **Network Type**: LXD macvlan for direct access
- **Host Access**: Isolated from host (L2 limitation)
- **External Access**: Direct from network clients
- **IP Range**: Host subnet

## Features

- Unified configuration supporting both bridge and macvlan networking
- Multi-environment support with Terraform workspaces (dev, staging, prod)
- Deploys LXC virtual machines with Ubuntu 22.04
- Installs and configures K3s
- Configurable CPU, memory, and storage
- Cloud-init for initial setup and SSH access

## Prerequisites

- Terraform >= 1.0
- LXD installed and configured on the host
- SSH key for ansible user access

## Quick Start

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Select workspace (dev, staging, or prod):
   ```bash
   terraform workspace select dev
   # or
   terraform workspace select prod
   ```

3. Use the idempotent wrapper script (recommended):
   ```bash
   # Deploy with bridge networking (single key)
   ./start-here.sh apply -var "ssh_public_keys=[\"$(cat id_ed25519.pub)\"]" -var "network_type=bridge"
   
   # Deploy with multiple keys
   ./start-here.sh apply -var "ssh_public_keys=[\"$(cat key1.pub)\",\"$(cat key2.pub)\"]" -var "network_type=bridge"
   
   # Deploy with macvlan networking
   ./start-here.sh apply -var "ssh_public_keys=[\"$(cat id_ed25519.pub)\"]" -var "network_type=macvlan"
   
   # Destroy
   ./start-here.sh destroy -var "ssh_public_keys=[\"$(cat id_ed25519.pub)\"]"
   ```

   Or use terraform directly (may require manual import for existing resources):
   ```bash
   terraform apply -var="ssh_public_keys=[\"$(cat id_ed25519.pub)\"]" -var="network_type=bridge"
   ```

   Or use terraform directly (may require manual import for existing resources):
   ```bash
   terraform apply -var="ssh_public_key=$(cat id_ed25519.pub)" -var="network_type=bridge"
   ```

## Environment Configuration

Each workspace has its own network configuration:

| Workspace | Bridge IPv4 | Macvlan Parent |
|-----------|-------------|----------------|
| dev       | 10.150.22.1/24 | enp4s0     |
| staging   | 10.150.20.1/24 | enp4s0     |
| prod      | 10.150.21.1/24 | enp4s0     |

## Testing and Verification

### Manual Testing
```bash
# Use the provided test scripts
./test-macvlan-connectivity.sh
./test-external-connectivity.sh
./vm-connectivity-test.sh
```

### Manual Verification
After deployment, verify with:
```bash
# Check VM status
lxc list | grep k3s

# Verify K3s service
lxc exec k3s-{env}-cluster-01 -- systemctl status k3s

# Check network configuration
lxc network show k3s-{env}-net
```

## Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| ssh_public_keys | List of SSH public key files for ansible user | Yes | - |
| network_type | Network type: bridge or macvlan | No | bridge |

## Outputs

| Output | Description |
|--------|-------------|
| k3s_node_ip | IPv4 address of the K3s node |
| check_commands | Commands to verify K3s and SSH setup |

## Security Notes

- SSH password authentication is disabled
- Ansible user has sudo privileges with no password
- Update the SSH key in cloud_config before deployment

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Here's how:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing-feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Troubleshooting

- Ensure LXD has permissions to create networks
- Check that the storage pool exists
- Use `terraform workspace list` to see available environments
- For network configuration issues, see TROUBLESHOOTING.md
