# LXC K3s Terraform Configuration

This Terraform configuration supports deploying multiple isolated K3s clusters (one per environment) in LXC virtual machines. Each environment (dev, staging, prod) gets its own cluster with separate networking and DNS configuration.

## Features

- Multi-environment support with Terraform workspaces
- Deploys LXC virtual machines with Ubuntu 22.04
- Installs and configures K3s
- Isolated bridge networks per environment
- Cloudflare DNS integration
- Configurable CPU, memory, and storage
- Cloud-init for initial setup and SSH access

## Prerequisites

- Terraform >= 1.0
- LXD installed and configured on the host
- Cloudflare account with API token
- SSH key for ansible user access

## Usage

1. Clone or copy this repository
2. Initialize Terraform:

```bash
terraform init
```

3. Create and select a workspace for your environment:

```bash
terraform workspace select dev  # or staging, prod
```

4. Plan the deployment (provide required variables):

```bash
terraform plan -var="cloudflare_api_token=your_token" -var="cloudflare_zone_id=your_zone" -var="tunnel_id=your_tunnel" -var="ssh_public_key=your_ssh_key"
```

5. Apply the configuration:

```bash
terraform apply -var="cloudflare_api_token=your_token" -var="cloudflare_zone_id=your_zone" -var="tunnel_id=your_tunnel" -var="ssh_public_key=your_ssh_key"
```

## Environments

The configuration supports three environments via Terraform workspaces:

- **dev**: Development environment with network 10.150.19.0/24
- **staging**: Staging environment with network 10.150.20.0/24
- **prod**: Production environment with network 10.150.21.0/24

Each environment gets:
- Unique cluster name (k3s-{env}-cluster-01)
- Isolated bridge network
- Environment-specific DNS subdomains

## Variables

| Variable | Description | Required |
|----------|-------------|----------|
| cloudflare_api_token | Cloudflare API token | Yes |
| cloudflare_zone_id | Cloudflare Zone ID | Yes |
| tunnel_id | Cloudflare tunnel ID | Yes |
| ssh_public_key | SSH public key for ansible user | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| k3s_node_ip | IPv4 address of the K3s node |
| check_commands | Commands to verify K3s and SSH setup |

## Networking

Each environment uses an isolated LXD bridge network with NAT, providing network isolation between environments while allowing internet access.

## Verification

After deployment, use the provided check commands to verify:

- K3s service is running
- SSH key is properly configured

```bash
# Check K3s status (replace {env} with your workspace)
lxc exec k3s-{env}-cluster-01 -- systemctl status k3s

# Verify SSH access
lxc exec k3s-{env}-cluster-01 -- cat /home/ansible/.ssh/authorized_keys
```

## Security Notes

- SSH password authentication is disabled
- Ansible user has sudo privileges with no password
- Update the SSH key in cloud_config before deployment

## Troubleshooting

- Ensure LXD has permissions to create networks
- Check that the storage pool exists
- Verify Cloudflare credentials are correct
- Use `terraform workspace list` to see available environments