variable "cloudflare_zone_id" {
  description = "The Cloudflare Zone ID for your domain"
  type        = string
}
variable "tunnel_id" {
  description = "tunnel id for your domain"
  type        = string
}
variable "app_subdomain" {
  description = "Subdomain for the app tunnel CNAME record"
  type        = string
  default     = "app"
}
variable "server_subdomain" {
  description = "Subdomain for the server A record"
  type        = string
  default     = "dallas-server"
}
variable "server_ip" {
  description = "IP address for the server A record"
  type        = string
  default     = "207.231.110.98"
}