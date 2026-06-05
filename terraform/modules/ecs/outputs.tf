output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_names" {
  value       = aws_ecs_service.eureka[*].name
  description = "Names of the two Eureka ECS services"
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}
