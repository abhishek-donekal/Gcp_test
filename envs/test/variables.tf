variable "project_id" {
  description = "Your personal GCP project ID (CI sets TF_VAR_project_id)."
  type        = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "iap_members" {
  description = "Who can SSH in, e.g. [\"user:you@gmail.com\"] (CI sets TF_VAR_iap_members)."
  type        = list(string)
}

variable "enable_nat" {
  description = "Outbound internet for the VMs (~$1/day)."
  type        = bool
  default     = false
}
