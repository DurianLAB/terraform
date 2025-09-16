# root main.tf

provider "lxd" {}

module "k3s_cluster_node" {
  source = "./module/lxc-k3s-vm"

  instance_name    = "my-k3s-node"
  image_alias      = "ubuntu-daily:22.04"
  ephemeral        = false
  network_name     = "k3s-network"
  ipv4_address     = "10.150.19.1/24"
  ipv6_address     = "fd42:474b:622d:259d::1/64"
  host_listen_ip   = "10.150.19.1"
  storage_pool     = "my-dir-pool"
}

output "k3s_node_ip" {
  value = module.k3s_cluster_node.instance_ip
}
