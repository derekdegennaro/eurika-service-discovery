provider "aws" {
  region = var.aws_region
}

locals {
  environment = "dev"
  name_prefix = "eurika-${local.environment}"
  tags = {
    Project     = "eurika-service-discovery"
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

module "networking" {
  source = "../../modules/networking"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_nat_gateway = false
  tags               = local.tags
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix     = local.name_prefix
  repository_name = "service-discovery"
  tags            = local.tags
}

module "ecs" {
  source = "../../modules/ecs"

  name_prefix              = local.name_prefix
  environment              = local.environment
  vpc_id                   = module.networking.vpc_id
  public_subnet_ids        = module.networking.public_subnet_ids
  task_subnets             = module.networking.public_subnet_ids
  assign_public_ip         = true
  image_uri                = var.image_uri
  task_cpu                 = var.task_cpu
  task_memory              = var.task_memory
  enable_self_preservation = false
  alb_internal             = true
  alb_allowed_cidr_blocks  = var.alb_allowed_cidr_blocks
  private_zone_id          = module.networking.private_zone_id
  private_zone_name        = module.networking.private_zone_name
  eureka_config = [
    {
      eureka_instance_hostname = "service-registry-0.${module.networking.private_zone_name}"
      eureka_service_url       = "http://service-registry-1.${module.networking.private_zone_name}/eureka/"
    },
    {
      eureka_instance_hostname = "service-registry-1.${module.networking.private_zone_name}"
      eureka_service_url       = "http://service-registry-0.${module.networking.private_zone_name}/eureka/"
    }
  ]
  log_retention_days       = 7
  tags                     = local.tags
}
