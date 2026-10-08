locals {
  project_id = var.project_id
  region     = var.region

  # Naming pieces. VM names come out as g-tst-us-app-general-a-001.
  environment_code = "tst"
  market_code      = "us"
  application      = "app"

  labels = {
    environment = "test"
    market      = local.market_code
    application = local.application
    managed_by  = "terraform"
  }

  # Bucket names are global — prefix with the project ID to keep them unique.
  bucket_prefix = "${local.project_id}-${local.environment_code}-${local.market_code}"
}
