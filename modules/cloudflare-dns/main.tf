terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# DNS record to point to the Cloudflare Tunnel
resource "cloudflare_record" "tunnel_cname" {
  zone_id = var.cloudflare_zone_id # Your Cloudflare Zone ID
  name    = var.app_subdomain # The subdomain for your application (e.g., app.yourdomain.com)
  content   = "${var.tunnel_id}.cfargotunnel.com" # The unique Tunnel ID
  type    = "CNAME"
  proxied = true
  ttl     = 1 # Automatic TTL
}
resource "cloudflare_record" "server_record" {
  zone_id = var.cloudflare_zone_id # Your Cloudflare Zone ID
  name    = var.server_subdomain # The subdomain for your application (e.g., app.yourdomain.com)
  content   = var.server_ip # The unique Tunnel ID
  type    = "A"
  proxied = true
  ttl     = 1 # Automatic TTL
}