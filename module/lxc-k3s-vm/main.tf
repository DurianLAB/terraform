terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

resource "lxd_network" "network" {
  name = var.network_name
  type = var.network_type

  count = var.network_type == "macvlan" ? 1 : 0

  config = var.network_type == "macvlan" ? {
    parent = var.parent_interface
  } : {}

  lifecycle {
    ignore_changes = [config]
  }
}

resource "lxd_network" "bridge_network" {
  name = var.network_name
  type = "bridge"

  count = var.network_type == "bridge" ? 1 : 0

  config = {
    "ipv4.address" = var.ipv4_address
    "ipv4.dhcp"   = "true"
  }

  lifecycle {
    ignore_changes = [config]
  }
}

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
      network = var.network_type == "macvlan" ? lxd_network.network[0].name : lxd_network.bridge_network[0].name
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

resource "lxd_instance" "app_instance" {
  name      = var.instance_name
  image     = var.image_alias
  ephemeral = var.ephemeral
  profiles  = [lxd_profile.instance_profile.name]
  type      = "virtual-machine"

  wait_for_network = true
}
