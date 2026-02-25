# Network Architecture Tradeoff Study

## Date: 2026-02-25

## Summary

Discussion on network architecture options for LXD/k3s cluster setup.

---

## Current Setup

- LXD virtual machines running k3s nodes
- Currently using bridge networking
- Storage pool using ZFS on dedicated disk (`k8s-storage` zpool)
- Terraform configuration at `/mnt/disk2/home/anpham/Project/terraform/lxc/`

---

## Network Options

### Option 1: Bridge Networking (current)

- Traffic goes through LXD bridge → host → physical network
- Simple setup, host can communicate with VMs
- Limited control over VM traffic

```
[Physical Router] ──► [LXD Bridge] ──► [k3s Nodes]
```

### Option 2: macvlan

- VMs get direct MAC on physical network
- Traffic goes directly VM ↔ switch ↔ router (no NAT)
- Router sees each VM as separate device

**Pros:**
- Direct network access, no NAT overhead
- VMs appear as separate devices on network

**Cons:**
- Router must support macvlan (port security/MAC limits)
- Host cannot communicate directly with VMs (needs extra config)
- Broadcast traffic can be noisy on larger networks
- Requires DHCP from main router

```
[Physical Router] ──► [macvlan] ──► [k3s Nodes]
```

### Option 3: pfSense as Router (recommended for control)

- pfSense VM with 2 NICs:
  - eth0 (WAN) → Physical Network → Main Router
  - eth1 (LAN) → LXD Bridge → k3s Nodes

**Traffic Flow:**
```
k3s Node ↔ LXD Bridge ↔ pfSense:eth1 ↔ pfSense:eth0 ↔ Main Router ↔ Internet
```

**IP Assignment Example (pfSense):**
```
pfSense VM:
  eth0 (WAN): 192.168.1.10/24  (from main router DHCP)
  eth1 (LAN): 10.0.10.1/24     (gateway for k3s nodes)

k3s-node-1:
  eth0: 10.0.10.11/24         (from pfSense DHCP)
  default via 10.0.10.1       (routes through pfSense)
```

**Pros:**
- Full control over firewall rules
- Dedicated DHCP for k3s nodes
- DNS management for cluster
- Traffic shaping/filtering
- Complete network isolation

**Cons:**
- Requires LXD support for multiple NICs per VM
- More complex setup
- pfSense needs 2 network interfaces

---

## Issues Identified

1. **Storage Pool Unavailable**: Initial Terraform config used `my-dir-pool` pointing to `/mnt/longhorn-nvme-data/pool/lxd` which was not mounted
   - Solution: Created new storage pool `lxd-terraform-pool` using existing ZFS pool `k8s-storage`

2. **OSD Disk Not Supported**: Attempted to pass through `/dev/sdb` to VMs for Ceph OSD
   - Issue: Filesystem mounting not supported in LXD virtual machines
   - Solution: Set `osd_disk_size = 0` to disable

3. **k3s Not Installed**: VMs initially didn't have k3s installed
   - Cause: cloud-init runcmd was still executing
   - Solution: Wait for cloud-init to complete (`cloud-init status --wait`)

---

## Action Items

- [ ] Add support for multiple NICs in Terraform LXD module
- [ ] Test pfSense VM with dual NICs
- [ ] Document network architecture decisions
- [ ] Consider performance implications of pfSense in VM

---

## Related Files

- `main.tf` - cluster configuration
- `module/lxc-k3s-vm/main.tf` - VM configuration
- `provider.tf` - LXD provider config
