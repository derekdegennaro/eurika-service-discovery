aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
vpc_cidr           = "10.1.0.0/16"
task_cpu           = 1024
task_memory        = 2048
# image_uri is set via TF_VAR_image_uri in GitHub Actions
