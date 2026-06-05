variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "image_uri" {
  type        = string
  description = "Full ECR image URI. Set via TF_VAR_image_uri in CI/CD."
}

variable "task_cpu" {
  type    = number
  default = 512
}

variable "task_memory" {
  type    = number
  default = 1024
}

variable "alb_allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to reach the ALB. Set via TF_VAR_alb_allowed_cidr_blocks in CI/CD."
}
