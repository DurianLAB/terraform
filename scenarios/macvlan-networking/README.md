# Macvlan Networking Scenario

This scenario deploys K3s clusters using LXD macvlan networks for direct external access.

## Characteristics

- **Network Type**: LXD Macvlan
- **IP Range**: Host subnet (192.168.1.x)
- **Host Access**: ❌ Isolated from host (L2 limitation)
- **External Access**: ✅ Direct access from network clients
- **Performance**: Better (no NAT overhead)
- **Use Case**: Production deployments

## Usage

```bash
cd scenarios/macvlan-networking
terraform init
terraform workspace select prod
terraform plan -var="ssh_public_key=$(cat ../../id_ed25519.pub)"
terraform apply -var="ssh_public_key=$(cat ../../id_ed25519.pub)"
```

## Network Access

- VMs are directly accessible from any device on the 192.168.1.x network
- Host cannot directly access VMs (normal macvlan behavior)
- External clients can connect directly to VM services

## Testing

Run the connectivity tests from the root directory:
```bash
ansible-playbook test-macvlan-ansible.yml
./test-macvlan-connectivity.sh
./test-external-connectivity.sh
```