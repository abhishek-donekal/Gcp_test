variable "project_id" {
  description = "Your personal GCP project ID."
  type        = string
}

variable "region" {
  description = "Default region."
  type        = string
  default     = "us-central1"
}

variable "github_repo" {
  description = "owner/repo allowed to deploy through Workload Identity Federation."
  type        = string
  default     = "abhishek-donekal/Gcp_test"
}

variable "pool_id" {
  description = "Workload Identity Pool ID. Deleted pools are soft-deleted for 30 days, so pick a new ID if you destroy and re-create."
  type        = string
  default     = "github-pool"
}
