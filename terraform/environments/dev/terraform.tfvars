aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
vpc_cidr           = "10.0.0.0/16"
task_cpu           = 512
task_memory        = 1024
# image_uri is set via TF_VAR_image_uri in GitHub Actions
