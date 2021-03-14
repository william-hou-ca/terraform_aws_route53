output "public_zone_nameservers" {
  value = aws_route53_zone.main.name_servers
}