variable "lxd_auth_token" {
  description = "The authentication token for the LXD remote host."
  type        = string
  sensitive   = true # This prevents the value from being displayed in output
}
