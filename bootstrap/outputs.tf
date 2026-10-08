# Copy these into GitHub → Settings → Secrets and variables → Actions → Variables.

output "GCP_PROJECT_ID" {
  value = var.project_id
}

output "GCP_WIF_PROVIDER" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "GCP_DEPLOYER_SA" {
  value = google_service_account.deployer.email
}

output "TF_STATE_BUCKET" {
  value = google_storage_bucket.tfstate.name
}
