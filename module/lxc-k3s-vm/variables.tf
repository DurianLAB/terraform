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
  description = "The name of the LXD bridge network."
  type        = string
}

variable "ipv4_address" {
  description = "IPv4 address range for the bridge network."
  type        = string
}

variable "ipv6_address" {
  description = "IPv6 address range for the bridge network."
  type        = string
}

variable "host_listen_ip" {
  description = "Host listen IP (not used in current config)."
  type        = string
  default     = ""
}

variable "storage_pool" {
  description = "The name of the LXD storage pool for the instance."
  type        = string
  default     = "default"
}

variable "cloud_config" {
  description = "The cloud-init configuration for the instance."
  type        = string
  default     = ""
}

variable "cpu_count" {
  description = "Number of CPUs for the instance."
  type        = number
  default     = 2
}

variable "memory_gb" {
  description = "Amount of memory in GB for the instance."
  type        = number
  default     = 2
}

variable "parent_interface" {
  description = "The parent network interface on the host for macvlan."
  type        = string
  default     = "eth0"
}
