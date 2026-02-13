output "instance_name" {
  value = lxd_instance.app_instance.name
}

output "instance_ip" {
  value = lxd_instance.app_instance.ipv4_address
}

output "status" {
  value = lxd_instance.app_instance.status
}
