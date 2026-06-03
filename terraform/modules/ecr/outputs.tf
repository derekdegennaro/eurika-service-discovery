output "repository_url" {
  value = one(aws_ecr_repository.main[*].repository_url)
}

output "repository_arn" {
  value = one(aws_ecr_repository.main[*].arn)
}
