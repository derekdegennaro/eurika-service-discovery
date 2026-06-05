output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "private_zone_id" {
  value       = aws_route53_zone.private.zone_id
  description = "Route53 private hosted zone ID"
}

output "private_zone_name" {
  value       = aws_route53_zone.private.name
  description = "Route53 private hosted zone domain name"
}
