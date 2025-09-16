terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

# Define the custom network for the instances
resource "lxd_network" "custom_network" {
  name = var.network_name

  config = {
    "ipv4.address" = var.ipv4_address
    "ipv4.nat"     = "true"
    "ipv6.address" = var.ipv6_address
    "ipv6.nat"     = "true"
  }
}

# Define the custom profile to link the instance to the network
resource "lxd_profile" "instance_profile" {
  name = "${var.instance_name}-profile"

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = lxd_network.custom_network.name
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

  config = {
    "user.user-data" = <<-EOF
      #cloud-config
      runcmd:
        - apt-get update -y
        - curl -sfL https://get.k3s.io | sh -
    EOF
  }
}

# Create the network forwarding rule
resource "lxd_network_forward" "forward_rule" {
  network        = lxd_network.custom_network.name
  listen_address = var.host_listen_ip

  ports = [
    {
      description  = "K3s API Server"
      protocol     = "tcp"
      listen_port  = 6443
      target_port  = 6443
      target_address = lxd_instance.app_instance.ipv4_address
    },
    {
      description  = "HTTP Ingress"
      protocol     = "tcp"
      listen_port  = 80
      target_port  = 80
      target_address = lxd_instance.app_instance.ipv4_address
    },
    {
      description  = "HTTPS Ingress"
      protocol     = "tcp"
      listen_port  = 443
      target_port  = 443
      target_address = lxd_instance.app_instance.ipv4_address
    }
  ]
}
