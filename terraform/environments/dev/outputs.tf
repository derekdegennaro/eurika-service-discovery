output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL for pushing images"
}

output "eureka_url" {
  value       = "http://${module.ecs.alb_dns_name}/eureka/"
  description = "Eureka service URL for client registration"
}

output "eureka_dashboard" {
  value       = "http://${module.ecs.alb_dns_name}"
  description = "Eureka dashboard URL"
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}
