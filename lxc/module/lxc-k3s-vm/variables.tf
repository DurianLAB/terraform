variable "instance_name" {
  description = "The name of the LXD instance."
  type        = string
}

variable "image_alias" {
  description = "The image alias for the instance (e.g., ubuntu/jammy)."
  type        = string
}

variable "ephemeral" {
  description = "Whether the instance should be ephemeral."
  type        = bool
  default     = false
}

variable "network_name" {
  description = "The name of the custom LXD network."
  type        = string
}

variable "ipv4_address" {
  description = "The IPv4 CIDR for the custom network."
  type        = string
}

variable "ipv6_address" {
  description = "The IPv6 CIDR for the custom network."
  type        = string
}

variable "host_listen_ip" {
  description = "The IP of the host machine to listen on for forwarding rules."
  type        = string
}

variable "storage_pool" {
  description = "The name of the LXD storage pool for the instance."
  type        = string
  default     = "default"
}
