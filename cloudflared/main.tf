terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4.0" # Use the latest stable version
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "cloudflare_dns" {
  source = "./modules/cloudflare-dns"

  cloudflare_zone_id = var.cloudflare_zone_id
  tunnel_id          = var.tunnel_id
  app_subdomain      = "app"
  server_subdomain   = "dallas-server"
  server_ip          = "207.231.110.98"
}
