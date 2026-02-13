

variable "ssh_public_key" {
  description = "SSH public key for ansible user"
  type        = string
  sensitive   = true
}

variable "network_type" {
  description = "Network type: bridge or macvlan"
  type        = string
  default     = "bridge"
}

