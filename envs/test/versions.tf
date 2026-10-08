terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 7.0"
    }
  }

  # Bucket is passed at init time so no project ID is committed:
  #   terraform init -backend-config="bucket=<project-id>-tfstate"
  backend "gcs" {
    prefix = "envs/test"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
