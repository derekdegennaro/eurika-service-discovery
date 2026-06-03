variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones to create subnets in"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Create NAT gateways for private subnets (costs money; set false in dev)"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}
