variable "instance_name" {
  description = "Name of the LXD instance"
  type        = string
}

variable "image_alias" {
  description = "LXD image alias to use"
  type        = string
}

variable "ephemeral" {
  description = "Whether the instance should be ephemeral"
  type        = bool
  default     = false
}

variable "network_name" {
  description = "Name of the LXD network"
  type        = string
}

variable "parent_interface" {
  description = "Parent network interface for macvlan"
  type        = string
}

variable "storage_pool" {
  description = "LXD storage pool to use"
  type        = string
}

variable "cpu_count" {
  description = "Number of CPU cores"
  type        = number
}

variable "memory_gb" {
  description = "Amount of memory in GB"
  type        = number
}

variable "cloud_config" {
  description = "Cloud-init configuration"
  type        = string
  default     = ""
}