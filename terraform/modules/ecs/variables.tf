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

variable "desired_count" {
  type        = number
  description = "Number of Eureka server tasks to run"
  default     = 2
}

variable "enable_self_preservation" {
  type        = bool
  description = "Enable Eureka self-preservation mode (disable in dev, enable in prod)"
  default     = false
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
