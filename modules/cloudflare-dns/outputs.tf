output "tunnel_cname_fqdn" {
  description = "The fully qualified domain name of the tunnel CNAME record"
  value       = cloudflare_record.tunnel_cname.hostname
}

output "server_record_fqdn" {
  description = "The fully qualified domain name of the server A record"
  value       = cloudflare_record.server_record.hostname
}