
output "amazon_prometheus_ingest_iam_role_arn" {
  value = module.aws-eks-accelerator-for-terraform.amazon_prometheus_ingest_iam_role_arn
}

output "amazon_prometheus_workspace_id" {
  value = module.aws-eks-accelerator-for-terraform.amazon_prometheus_workspace_id
}

output "amazon_prometheus_ingest_service_account" {
  value = module.aws-eks-accelerator-for-terraform.amazon_prometheus_ingest_service_account
}
