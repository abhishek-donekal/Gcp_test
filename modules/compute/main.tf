# ==============================================================================
# Standalone VMs, one per gce_instances key.
#
# Each VM gets its OWN service account with a stable, readable name
# (<env>-<market>-<key>), so bucket grants survive an instance rebuild.
# Additional disks are separate resources: rebuilding a VM never deletes them.
# ==============================================================================

locals {
  base_name = join("-", [var.name_prefix, var.environment_code, var.market_code, var.application])

  instances = {
    for k, v in var.gce_instances : k => merge(v, {
      name = lower("${local.base_name}-${v.purpose}-${substr(v.zone, -1, 1)}-${v.increment}")
    })
  }

  disks = merge([
    for k, v in local.instances : {
      for d in v.additional_disks : "${k}/${d.device_name}" => merge(d, {
        instance = k
        zone     = v.zone
        name     = "${v.name}-${d.device_name}"
      })
    }
  ]...)

  sa_bindings = {
    for pair in setproduct(keys(local.instances), var.iap_members) :
    "${pair[0]}/${pair[1]}" => { instance = pair[0], member = pair[1] }
  }
}

resource "google_service_account" "vm" {
  for_each = local.instances

  project      = var.project_id
  account_id   = substr(lower("${var.environment_code}-${var.market_code}-${each.key}"), 0, 30)
  display_name = "VM ${each.value.name}"
}

# Minimal runtime permissions so the VM can ship logs/metrics.
resource "google_project_iam_member" "vm_logging" {
  for_each = local.instances

  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm[each.key].email}"
}

resource "google_project_iam_member" "vm_monitoring" {
  for_each = local.instances

  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm[each.key].email}"
}

# OS Login on a VM that runs as a service account requires actAs on that SA.
resource "google_service_account_iam_member" "iap_act_as" {
  for_each = local.sa_bindings

  service_account_id = google_service_account.vm[each.value.instance].name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value.member
}

resource "google_compute_disk" "additional" {
  for_each = local.disks

  project = var.project_id
  name    = each.value.name
  zone    = each.value.zone
  size    = each.value.size_gb
  type    = each.value.type
  labels  = merge(var.labels, { purpose = each.value.device_name })
}

resource "google_compute_instance" "this" {
  for_each = local.instances

  project                   = var.project_id
  name                      = each.value.name
  zone                      = each.value.zone
  machine_type              = each.value.machine_type
  tags                      = ["iap-ssh"]
  labels                    = var.labels
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image  = each.value.boot_disk_image
      size   = each.value.boot_disk_size_gb
      type   = each.value.boot_disk_type
      labels = var.labels
    }
  }

  dynamic "attached_disk" {
    for_each = { for k, d in local.disks : k => d if d.instance == each.key }
    content {
      source      = google_compute_disk.additional[attached_disk.key].id
      device_name = attached_disk.value.device_name
    }
  }

  # No access_config block => no external IP.
  network_interface {
    subnetwork = var.subnet_id
  }

  service_account {
    email  = google_service_account.vm[each.key].email
    scopes = ["cloud-platform"]
  }

  metadata = merge(var.metadata, {
    enable-oslogin = "TRUE"
    startup-script = var.startup_script
  })

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}
