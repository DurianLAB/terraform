<<<<<<< HEAD
terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4.0" # Use the latest stable version
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "cloudflare_dns" {
  source = "./modules/cloudflare-dns"

  cloudflare_zone_id = var.cloudflare_zone_id
  tunnel_id          = var.tunnel_id
  app_subdomain      = "app"
  server_subdomain   = "dallas-server"
  server_ip          = "207.231.110.98"
=======
# root main.tf


module "k3s_cluster_node" {
  source = "./module/lxc-k3s-vm"

  instance_name    = "k3s-ubuntu-cluster-01"
  image_alias      = "ubuntu-daily:22.04"
  ephemeral        = false
  parent_interface = "enp4s0"
  storage_pool     = "my-dir-pool"
  cpu_count        = 2
  memory_gb        = 2
    cloud_config   = <<-EOF
     #cloud-config
     hostname: k3s-master
     ssh_pwauth: false

     users:
       - name: ansible
         shell: /bin/bash
         sudo: ALL=(ALL) NOPASSWD:ALL
         ssh_authorized_keys:
           - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICa5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5 ansible@my-machine

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
>>>>>>> 820ef66 (generate new branch)
}
