variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names"
}

variable "repository_name" {
  type        = string
  description = "ECR repository name"
}

variable "image_tag_mutability" {
  type        = string
  description = "Image tag mutability (MUTABLE or IMMUTABLE)"
  default     = "MUTABLE"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}

variable "create_repository" {
  type        = bool
  description = "Whether to create the ECR repository (true in dev, false in prod)"
  default     = false
}

