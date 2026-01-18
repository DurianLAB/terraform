#!/bin/bash
# Test script to run from external machine on network
# Replace VM_IP with your VM's IP address

VM_IP="192.168.1.148"
SSH_USER="ansible"

echo "=== External Network Connectivity Test ==="
echo "Testing connectivity to VM at $VM_IP"
echo ""

echo "1. Testing ping connectivity..."
ping -c 3 "$VM_IP"
echo ""

echo "2. Testing SSH connectivity..."
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" "echo 'SSH connection successful'" 2>/dev/null || echo "SSH test failed"
echo ""

echo "3. Testing K3s API server (if running)..."
curl -k --connect-timeout 5 https://"$VM_IP":6443/version 2>/dev/null | head -5 || echo "K3s API test failed"
echo ""

echo "4. Testing common ports..."
echo "   Port 22 (SSH):"
nc -z -w3 "$VM_IP" 22 && echo "✓ Open" || echo "✗ Closed"
echo "   Port 6443 (K3s API):"
nc -z -w3 "$VM_IP" 6443 && echo "✓ Open" || echo "✗ Closed"
echo ""

echo "=== Test Complete ==="