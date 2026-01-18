# Bridge Networking Scenario - Development/Testing Environment
# This configuration uses LXD bridge networks for isolated environments
# VMs are accessible from the host but require NAT for external access

terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

# Create a bridge network for the environment
resource "lxd_network" "bridge_network" {
  name = var.network_name
  type = "bridge"

  config = {
    "ipv4.address" = var.ipv4_address
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
  }
}

# Define the custom profile to link the instance to the network
resource "lxd_profile" "instance_profile" {
  name = "${var.instance_name}-profile"

  config = {
    "user.user-data" = var.cloud_config != "" ? var.cloud_config : ""
    "limits.cpu"     = tostring(var.cpu_count)
    "limits.memory"  = "${var.memory_gb}GB"
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = lxd_network.bridge_network.name
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = var.storage_pool
      path = "/"
    }
  }
}

# Create the VM instance
resource "lxd_instance" "app_instance" {
  name      = var.instance_name
  image     = var.image_alias
  ephemeral = var.ephemeral
  profiles  = [lxd_profile.instance_profile.name]
  type      = "virtual-machine"
}