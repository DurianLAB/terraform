output "instance_ip" {
  description = "The IPv4 address of the created LXD instance."
  value       = lxd_instance.app_instance.ipv4_address
}

output "instance_name" {
  description = "The name of the created LXD instance."
  value       = lxd_instance.app_instance.name
}
