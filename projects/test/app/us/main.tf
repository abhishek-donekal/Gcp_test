# ==============================================================================
# Test environment — single market (US), us-central1.
#
#   network  : private VPC + one app subnet, IAP-only SSH, optional NAT
#   buckets  : data (versioned) + staging (objects auto-delete after 7 days)
#   compute  : vm-01, a small Debian VM with a separate 10 GB workspace disk
#
# The VM's own service account gets objectAdmin + legacyBucketReader on both
# buckets, so `gsutil ls gs://<bucket>` works from the box out of the box.
#
# Sized for the free tier: e2-micro + 20 GB boot + 10 GB data on pd-standard.
# To add a VM, add a key to gce_instances below — nothing else is touched.
# ==============================================================================

module "network" {
  source = "../../../../modules/network"

  project_id = local.project_id
  region     = local.region
  name       = "${local.environment_code}-${local.market_code}"
  enable_nat = var.enable_nat
}

module "buckets" {
  source = "../../../../modules/gcs_bucket"

  project_id  = local.project_id
  location    = upper(local.region)
  name_prefix = local.bucket_prefix
  labels      = local.labels

  buckets = {
    data = {
      versioning = true
    }
    staging = {
      lifecycle_age_days = 7
    }
  }

  writers = {
    data    = [for email in values(module.compute.service_account_emails) : "serviceAccount:${email}"]
    staging = [for email in values(module.compute.service_account_emails) : "serviceAccount:${email}"]
  }
}

module "compute" {
  source = "../../../../modules/compute"

  project_id       = local.project_id
  subnet_id        = module.network.subnet_id
  environment_code = local.environment_code
  market_code      = local.market_code
  application      = local.application
  labels           = local.labels
  iap_members      = var.iap_members

  startup_script = file("${path.module}/startup.sh")

  # Read by startup.sh via the metadata server.
  metadata = {
    data-bucket    = "gs://${local.bucket_prefix}-data"
    staging-bucket = "gs://${local.bucket_prefix}-staging"
  }

  gce_instances = {
    "vm-01" = {
      zone         = "${local.region}-a"
      increment    = "001"
      machine_type = "e2-micro"

      additional_disks = [
        {
          # MUST match what startup.sh waits for: /dev/disk/by-id/google-workspace
          device_name = "workspace"
          size_gb     = 10
        }
      ]
    }

    # Example second VM — uncomment to add one alongside vm-01:
    # "vm-02" = {
    #   zone         = "${local.region}-a"
    #   increment    = "002"
    #   machine_type = "e2-small"
    # }
  }
}

# Lets the people in iap_members open an IAP tunnel and log in via OS Login.
resource "google_project_iam_member" "iap_tunnel" {
  for_each = toset(var.iap_members)

  project = local.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = each.value
}

resource "google_project_iam_member" "os_admin_login" {
  for_each = toset(var.iap_members)

  project = local.project_id
  role    = "roles/compute.osAdminLogin"
  member  = each.value
}
