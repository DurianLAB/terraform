

variable "ssh_public_key" {
  description = "SSH public key for ansible user"
  type        = string
  sensitive   = true
}

