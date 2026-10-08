terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 7.0"
    }
  }

  # Bootstrap keeps LOCAL state on purpose: it creates the remote state bucket
  # everything else uses. Run it once from Cloud Shell; keep terraform.tfstate
  # somewhere safe (it is gitignored).
}

provider "google" {
  project = var.project_id
  region  = var.region
}
