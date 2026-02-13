output "instance_name" {
  value = lxd_instance.app_instance.name
}

output "instance_ip" {
  value = lxd_instance.app_instance.ip_address
}

output "instance_id" {
  value = lxd_instance.app_instance.id
}

output "status" {
  value = lxd_instance.app_instance.status
}
