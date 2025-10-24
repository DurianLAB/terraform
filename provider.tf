terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4.0" # Use the latest stable version
    }
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.5.0"
    }
  }
}

