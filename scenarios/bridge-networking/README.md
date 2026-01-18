# Bridge Networking Scenario

This scenario deploys K3s clusters using LXD bridge networks.

## Characteristics

- **Network Type**: LXD Bridge with NAT
- **IP Range**: Isolated subnet (10.150.x.x)
- **Host Access**: ✅ Direct access to VMs
- **External Access**: ❌ Requires port forwarding/NAT
- **Performance**: Good
- **Use Case**: Development and testing environments

## Usage

```bash
cd scenarios/bridge-networking
terraform init
terraform workspace select dev
terraform plan -var="ssh_public_key=$(cat ../../id_ed25519.pub)"
terraform apply -var="ssh_public_key=$(cat ../../id_ed25519.pub)"
```

## Network Access

- VMs are accessible from the host machine
- External access requires port forwarding through the host
- Use `lxc list` to find VM IPs in the 10.150.x.x range

## Testing

Run the connectivity tests from the root directory:
```bash
ansible-playbook test-macvlan-ansible.yml
```