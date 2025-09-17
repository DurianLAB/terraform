variable "cloudflare_api_token" {
  description = "The Cloudflare API token for authentication."
  type        = string
  sensitive   = true # Marks the variable as sensitive
}
variable "cloudflare_zone_id" {
  description = "The Cloudflare Zone ID for your domain"
  type        = string
}
variable "tunnel_id" {
  description = "tunnel id for your domain"
  type        = string
}

