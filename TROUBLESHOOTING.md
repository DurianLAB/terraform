# LXD Macvlan/Bridge Network Configuration - Troubleshooting Guide

## Unified Configuration

Since the update to use a unified configuration with `network_type` variable, you can now deploy both bridge and macvlan networks from a single Terraform setup:

```bash
# Bridge networking
terraform apply -var="ssh_public_key=$(cat key.pub)" -var="network_type=bridge"

# Macvlan networking
terraform apply -var="ssh_public_key=$(cat key.pub)" -var="network_type=macvlan"
```

## Issue Summary
Terraform deployments of LXD virtual machines fail during startup with the error: `Failed to start device "eth0": Parent device 'k3s-prod-net' doesn't exist`, even though the LXD network exists and works correctly for manual container/VM creation.

## Symptoms
- Terraform `apply` command fails when creating LXD virtual machines
- Error message: `Failed to start device "eth0": Parent device 'k3s-prod-net' doesn't exist`
- The LXD network appears to exist when checked with `lxc network list`
- Manual creation of containers/VMs with the same network works fine
- Issue occurs specifically with Terraform-managed LXD profiles

## Root Cause Analysis
The issue stems from incorrect network device configuration in the LXD profile used by Terraform. The Terraform configuration was manually specifying macvlan parameters instead of using LXD's managed network feature:

**Incorrect Configuration:**
```hcl
device {
  name = "eth0"
  type = "nic"
  properties = {
    nictype = "macvlan"
    parent  = lxd_network.macvlan_network.name
  }
}
```

This tells LXD to create a macvlan interface with parent device `k3s-prod-net`, but `k3s-prod-net` is a managed LXD network, not a physical network interface.

**Correct Configuration:**
```hcl
device {
  name = "eth0"
  type = "nic"
  properties = {
    network = lxd_network.macvlan_network.name
  }
}
```

This uses LXD's managed network feature, where the network name refers to the managed network resource.

## Solution Steps

### 1. Identify the Problem
Check if the network exists and is functional:
```bash
lxc network list
lxc network show <network-name>
```

Test manual creation to confirm network works:
```bash
lxc launch ubuntu:22.04 test-container --network <network-name>
lxc launch ubuntu:22.04 test-vm --network <network-name> --vm
```

### 2. Fix Terraform Configuration
Edit the LXD profile configuration in your Terraform module:

**File:** `module/lxc-k3s-vm/main.tf`

**Change from:**
```hcl
device {
  name = "eth0"
  type = "nic"
  properties = {
    nictype = "macvlan"
    parent  = lxd_network.macvlan_network.name
  }
}
```

**Change to:**
```hcl
device {
  name = "eth0"
  type = "nic"
  properties = {
    network = lxd_network.macvlan_network.name
  }
}
```

### 3. Clean Up Existing Resources
If Terraform state is corrupted, manually clean up:

```bash
# Stop and delete the problematic instance
lxc stop <instance-name>
lxc delete <instance-name>

# Delete the profile (if it exists)
lxc profile delete <profile-name>

# Optionally delete and recreate the network
lxc network delete <network-name>
```

### 4. Reapply Terraform Configuration
```bash
terraform apply -var="ssh_public_key=$(cat <key-file>)" -auto-approve
```

## Verification Steps
1. Check that the VM is running:
   ```bash
   lxc list | grep <instance-name>
   ```

2. Verify network connectivity:
   ```bash
   lxc exec <instance-name> -- ip addr show eth0
   ```

3. Test SSH access:
   ```bash
   ssh ansible@<vm-ip>
   ```

4. Check k3s service status (if applicable):
   ```bash
   lxc exec <instance-name> -- systemctl status k3s
   ```

## Prevention Measures
1. **Use managed networks properly:** Always use `network = <network-name>` for LXD managed networks instead of manual `nictype` and `parent` configuration.

2. **Test configurations manually:** Before deploying via Terraform, test network configurations manually with `lxc launch --network <network>`.

3. **Version control network configurations:** Keep network setup and instance configurations in separate, well-documented Terraform modules.

4. **Monitor Terraform state:** Regularly check Terraform state consistency and clean up orphaned resources.

## Key Differences: Manual vs Terraform Network Configuration

| Method | Device Configuration | Result |
|--------|---------------------|---------|
| Manual LXC | `network: <network-name>` | ✅ Works |
| Terraform (incorrect) | `nictype: macvlan, parent: <network-name>` | ❌ Fails |
| Terraform (correct) | `network: <network-name>` | ✅ Works |

## Related Commands Reference
```bash
# Network management
lxc network list
lxc network show <name>
lxc network create <name> type=macvlan parent=<interface>

# Instance management
lxc list
lxc launch <image> <name> --network <network> [--vm]
lxc stop <name>
lxc delete <name>

# Profile management
lxc profile list
lxc profile show <name>
lxc profile delete <name>

# Terraform operations
terraform plan
terraform apply -var="ssh_public_key=$(cat key.pub)"
terraform state list
terraform state show <resource>
```

## Additional Notes
- This issue affects virtual machines more commonly than containers due to different network device handling
- The problem manifests only when using managed LXD networks (bridge/macvlan) created via Terraform
- Physical network interfaces work fine with `nictype: macvlan` and `parent: <physical-interface>` configuration

**Document Version:** 1.0
**Last Updated:** January 17, 2026
**Author:** System Engineer
**Related Components:** Terraform, LXD, Macvlan networking