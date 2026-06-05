output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL for pushing images"
}

output "eureka_url" {
  value       = "http://${module.ecs.alb_dns_name}/eureka/"
  description = "Eureka service URL for client registration"
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_names" {
  value = module.ecs.service_names
}

output "private_zone_id" {
  value       = module.networking.private_zone_id
  description = "Route53 private hosted zone ID"
}

output "private_zone_name" {
  value       = module.networking.private_zone_name
  description = "Route53 private hosted zone domain name"
}
