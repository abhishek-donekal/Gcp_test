# Daily snapshots of every boot + additional disk in this call.
# Adding a VM picks its disks up automatically.

locals {
  snapshots_on = var.enable_snapshots && length(local.instances) > 0
}

resource "google_compute_resource_policy" "snapshots" {
  count = local.snapshots_on ? 1 : 0

  project = var.project_id
  name    = "${local.base_name}-daily-snap"
  region  = join("-", slice(split("-", values(local.instances)[0].zone), 0, 2))

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }
    retention_policy {
      max_retention_days    = var.snapshot_retention_days
      on_source_disk_delete = "APPLY_RETENTION_POLICY"
    }
    snapshot_properties {
      labels = var.labels
    }
  }
}

locals {
  snapshot_targets = local.snapshots_on ? merge(
    { for k, v in local.instances : "${k}/boot" => { disk = google_compute_instance.this[k].name, zone = v.zone } },
    { for k, d in local.disks : k => { disk = google_compute_disk.additional[k].name, zone = d.zone } },
  ) : {}
}

resource "google_compute_disk_resource_policy_attachment" "snapshots" {
  for_each = local.snapshot_targets

  project = var.project_id
  name    = google_compute_resource_policy.snapshots[0].name
  disk    = each.value.disk
  zone    = each.value.zone
}
