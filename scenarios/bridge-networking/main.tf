# root main.tf

locals {
  env_configs = {
    dev = {
      ipv4_address = "10.150.22.1/24"
      server_ip    = "10.150.22.2"  # Example IP, adjust as needed
    }
    staging = {
      ipv4_address = "10.150.20.1/24"
      server_ip    = "10.150.20.2"
    }
    prod = {
      ipv4_address = "10.150.21.1/24"
      server_ip    = "10.150.21.2"
    }
  }
  current_env = lookup(local.env_configs, terraform.workspace, local.env_configs["dev"])
}

module "k3s_cluster_node" {
  source = "./module/lxc-k3s-vm"
  instance_name = "k3s-${terraform.workspace}-cluster-01"
  image_alias   = "ubuntu-daily:22.04"
  ephemeral     = false
  network_name  = "k3s-${terraform.workspace}-net"
  ipv4_address  = local.current_env.ipv4_address
  storage_pool  = "my-dir-pool"
  cpu_count     = 2
  memory_gb     = 2
  cloud_config  = <<-EOF
     #cloud-config
     hostname: k3s-${terraform.workspace}-master
     ssh_pwauth: false

     users:
        - name: ansible
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          ssh_authorized_keys:
            - ${join("\n            - ", [for f in var.ssh_public_keys : file(f)])}

     runcmd:
       - apt-get update -y
       - apt-get install -y python3 python3-pip apt-transport-https ca-certificates curl gnupg
       - ln -sf /usr/bin/python3 /usr/bin/python
       - curl -sfL https://get.k3s.io | sh -
   EOF
}

output "k3s_node_ip" {
  value = module.k3s_cluster_node.instance_ip
}

output "check_commands" {
  description = "Commands to verify k3s is running and SSH key is present"
  value = <<-EOF
  # Check if k3s is running
  lxc exec ${module.k3s_cluster_node.instance_name} -- systemctl status k3s

  # Check if SSH public key is present
  lxc exec ${module.k3s_cluster_node.instance_name} -- cat /home/ansible/.ssh/authorized_keys
  EOF
}
