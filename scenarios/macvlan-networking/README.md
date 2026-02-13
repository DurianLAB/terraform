# Macvlan Networking Scenario (Deprecated)

> **⚠️ This scenario is deprecated.** Please use the unified configuration in the root directory instead.

This scenario deploys K3s clusters using LXD macvlan networks for direct external access.

## Characteristics

- **Network Type**: LXD Macvlan
- **IP Range**: Host subnet (e.g., 192.168.1.x)
- **Host Access**: ❌ Isolated from host (L2 limitation)
- **External Access**: ✅ Direct access from network clients
- **Performance**: Better (no NAT overhead)
- **Use Case**: Production deployments

## Recommended Usage

Use the unified configuration in the root directory:

```bash
cd ..
terraform init
terraform workspace select prod
terraform plan -var="ssh_public_key=$(cat ../id_ed25519.pub)" -var="network_type=macvlan"
terraform apply -var="ssh_public_key=$(cat ../id_ed25519.pub)" -var="network_type=macvlan"
```

## Legacy Usage

```bash
cd scenarios/macvlan-networking
terraform init
terraform workspace select prod
terraform plan -var="ssh_public_key=$(cat ../../id_ed25519.pub)"
terraform apply -var="ssh_public_key=$(cat ../../id_ed25519.pub)"
```

## Network Access

- VMs are directly accessible from any device on the host network
- Host cannot directly access VMs (normal macvlan behavior)
- External clients can connect directly to VM services
