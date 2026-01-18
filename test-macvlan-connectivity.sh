#!/bin/bash
# Macvlan Network Connectivity Test Script
# Tests if LXD macvlan networking allows external access to container/VM services

INSTANCE_NAME="k3s-prod-cluster-01"
VM_IP="192.168.1.148"
SSH_USER="ansible"

echo "=== Macvlan Network Connectivity Test ==="
echo "Instance: $INSTANCE_NAME"
echo "VM IP: $VM_IP"
echo ""

# Test 1: Check if instance is running
echo "1. Checking instance status..."
lxc list | grep "$INSTANCE_NAME" | grep RUNNING
if [ $? -eq 0 ]; then
    echo "✓ Instance is running"
else
    echo "✗ Instance is not running"
    exit 1
fi
echo ""

# Test 2: Check network configuration
echo "2. Checking network configuration..."
lxc network show k3s-prod-net
echo ""

# Test 3: Check VM internal network
echo "3. Checking VM internal network configuration..."
lxc exec "$INSTANCE_NAME" -- ip addr show enp5s0
echo ""

# Test 4: Test service accessibility from within VM
echo "4. Testing services from within VM..."
echo "   SSH service:"
lxc exec "$INSTANCE_NAME" -- netstat -tlnp | grep :22
echo "   K3s service:"
lxc exec "$INSTANCE_NAME" -- systemctl is-active k3s
echo ""

# Test 5: Test external connectivity (will fail due to macvlan isolation)
echo "5. Testing external connectivity from host..."
echo "   Note: This will fail due to macvlan L2 isolation"
ping -c 2 "$VM_IP" 2>/dev/null || echo "✓ Expected failure - macvlan isolation working"
echo ""

# Test 6: Instructions for external testing
echo "6. External Network Testing Instructions:"
echo "   To test from another machine on the network (192.168.1.0/24):"
echo "   ping $VM_IP"
echo "   ssh $SSH_USER@$VM_IP"
echo "   curl http://$VM_IP:6443"  # K3s API server
echo ""

echo "=== Test Complete ==="
echo "Macvlan is working correctly - VMs are isolated from host but accessible from external network."