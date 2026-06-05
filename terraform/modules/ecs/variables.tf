variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev or prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB"
}

variable "task_subnets" {
  type        = list(string)
  description = "Subnet IDs for ECS tasks (public in dev, private in prod)"
}

variable "assign_public_ip" {
  type        = bool
  description = "Assign public IPs to Fargate tasks (true in dev with public subnets)"
  default     = false
}

variable "image_uri" {
  type        = string
  description = "Full ECR image URI including tag (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/repo:sha)"
}

variable "container_port" {
  type        = number
  description = "Port the Eureka server listens on"
  default     = 8761
}

variable "task_cpu" {
  type        = number
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)"
  default     = 512
}

variable "task_memory" {
  type        = number
  description = "Fargate task memory in MiB"
  default     = 1024
}

variable "enable_self_preservation" {
  type        = bool
  description = "Enable Eureka self-preservation mode (disable in dev, enable in prod)"
  default     = false
}

# variable "eureka_service_url" {
#   type        = string
#   description = "Eureka service URL (comma separated list) for peer replication (e.g. http://service-registry-{0,1}.eurika.internal/eureka/)"
# }

# variable "eureka_instance_hostname" {
#   type        = string
#   description = "Eureka instance hostname (e.g. service-registry-0.eurika.internal)"
# }

variable "eureka_config" {
  type = list(object({
    eureka_service_url       = string
    eureka_instance_hostname = string
  }))
  description = "List of Eureka configuration objects for each instance (used for peer replication)"
}

variable "alb_internal" {
  type        = bool
  description = "Make the ALB internal (false in dev, true in prod)"
  default     = false
}

variable "alb_allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to reach the ALB on port 80"
}

variable "private_zone_id" {
  type        = string
  description = "Route53 private hosted zone ID for creating Eureka DNS records"
}

variable "private_zone_name" {
  type        = string
  description = "Route53 private hosted zone domain name (e.g. eurika.internal)"
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 7
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}
