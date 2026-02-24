
variable "node_count" {
  description = "Number of k3s nodes to create"
  type        = number
  default     = 3
}

variable "ssh_public_keys" {
  description = "List of SSH public key files for ansible user"
  type        = list(string)
  default     = []
}

variable "network_type" {
  description = "Network type: bridge or macvlan"
  type        = string
  default     = "bridge"
}

