terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

# Create a macvlan network for the environment
resource "lxd_network" "macvlan_network" {
  name = var.network_name
  type = "macvlan"

  config = {
    parent = var.parent_interface
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
       network = lxd_network.macvlan_network.name
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


