

variable "ssh_public_keys" {
  description = "List of SSH public key files for ansible user"
  type        = list(string)
  default     = []
}

