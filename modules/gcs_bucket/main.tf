# ==============================================================================
# GCS buckets + writer access.
#
# Writers always get BOTH roles:
#   - roles/storage.objectAdmin       read/write/delete objects
#   - roles/storage.legacyBucketReader storage.buckets.get (bucket metadata)
#
# objectAdmin alone is a trap: gsutil and the Hadoop GCS connector call
# buckets.get before touching objects and fail with 403 even though object
# access looks fine. Granting them as a pair here makes that impossible.
#
# Bindings are AUTHORITATIVE per (bucket, role): anything not listed in
# var.writers is removed. That keeps access from sprawling over time.
# ==============================================================================

locals {
  writer_roles = ["roles/storage.objectAdmin", "roles/storage.legacyBucketReader"]

  bindings = {
    for pair in setproduct(keys(var.writers), local.writer_roles) :
    "${pair[0]}/${pair[1]}" => {
      bucket  = pair[0]
      role    = pair[1]
      members = var.writers[pair[0]]
    }
  }
}

resource "google_storage_bucket" "this" {
  for_each = var.buckets

  project                     = var.project_id
  name                        = "${var.name_prefix}-${each.key}"
  location                    = var.location
  storage_class               = each.value.storage_class
  force_destroy               = each.value.force_destroy
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = var.labels

  versioning {
    enabled = each.value.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_age_days == null ? [] : [each.value.lifecycle_age_days]
    content {
      condition {
        age = lifecycle_rule.value
      }
      action {
        type = "Delete"
      }
    }
  }
}

resource "google_storage_bucket_iam_binding" "writers" {
  for_each = local.bindings

  bucket  = google_storage_bucket.this[each.value.bucket].name
  role    = each.value.role
  members = each.value.members
}
