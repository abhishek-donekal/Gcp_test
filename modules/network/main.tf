# ==============================================================================
# Private VPC: one subnet, no public IPs. SSH only through IAP.
# ==============================================================================

resource "google_compute_network" "this" {
  project                 = var.project_id
  name                    = "vpc-${var.name}"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "app" {
  project       = var.project_id
  name          = "snet-${var.name}-app"
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = var.subnet_cidr

  # Lets VMs with no external IP reach GCS / Google APIs.
  private_ip_google_access = true
}

# IAP TCP forwarding comes from this fixed Google range.
resource "google_compute_firewall" "iap_ssh" {
  project       = var.project_id
  name          = "fw-${var.name}-allow-iap-ssh"
  network       = google_compute_network.this.id
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_router" "this" {
  count = var.enable_nat ? 1 : 0

  project = var.project_id
  name    = "rtr-${var.name}"
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  count = var.enable_nat ? 1 : 0

  project                            = var.project_id
  name                               = "nat-${var.name}"
  region                             = var.region
  router                             = google_compute_router.this[0].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
