# LXC K3s Terraform Module

This Terraform configuration deploys an LXC virtual machine running K3s (Kubernetes) using macvlan networking for direct host network access.

## Features

- Deploys LXC virtual machine with Ubuntu 22.04
- Installs and configures K3s
- Uses macvlan networking for direct host network integration
- Configurable CPU, memory, and storage
- Cloud-init for initial setup and SSH access

## Prerequisites

- Terraform >= 1.0
- LXD installed and configured on the host
- Host network interface available for macvlan (default: eth0)
- SSH key for ansible user access

## Usage

1. Clone or copy this repository
2. Update variables in `main.tf` as needed
3. Initialize Terraform:

```bash
terraform init
```

4. Plan the deployment:

```bash
terraform plan
```

5. Apply the configuration:

```bash
terraform apply
```

## Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| instance_name | Name of the LXC instance | - | Yes |
| image_alias | LXD image alias | ubuntu-daily:22.04 | Yes |
| ephemeral | Whether instance is ephemeral | false | No |
| parent_interface | Host network interface for macvlan | eth0 | No |
| storage_pool | LXD storage pool name | my-dir-pool | No |
| cpu_count | Number of CPU cores | 2 | No |
| memory_gb | Memory in GB | 2 | No |
| cloud_config | Cloud-init configuration | - | No |

## Outputs

| Output | Description |
|--------|-------------|
| k3s_node_ip | IPv4 address of the K3s node |
| check_commands | Commands to verify K3s and SSH setup |

## Networking

This configuration uses macvlan networking, which provides the LXC instance with direct access to the host's network. The instance will receive an IP address from the host's network subnet.

**Important:** Ensure the host's network interface supports macvlan and that your network allows multiple MAC addresses on the same port.

## Verification

After deployment, use the provided check commands to verify:

- K3s service is running
- SSH key is properly configured

```bash
# Check K3s status
lxc exec <instance_name> -- systemctl status k3s

# Verify SSH access
lxc exec <instance_name> -- cat /home/ansible/.ssh/authorized_keys
```

## Security Notes

- SSH password authentication is disabled
- Ansible user has sudo privileges with no password
- Update the SSH key in cloud_config before deployment

## Troubleshooting

- If macvlan doesn't work, check host interface compatibility
- Ensure LXD has necessary permissions for network operations
- Verify host firewall allows necessary traffic