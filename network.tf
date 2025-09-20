# Custom VPC Network
resource "google_compute_network" "paas_monitor" {
  name                    = "paas-monitor"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "paas_monitor" {
  for_each      = local.regions
  name          = "paas-monitor"
  ip_cidr_range = each.value
  region        = each.key
  network       = google_compute_network.paas_monitor.id

  private_ip_google_access = true
}

resource "google_compute_router" "paas_monitor" {
  for_each = local.regions
  name     = "paas-monitor"
  region   = each.key
  network  = google_compute_network.paas_monitor.id
}

resource "google_compute_router_nat" "paas_monitor" {
  for_each                           = local.regions
  name                               = "paas-monitor"
  router                             = google_compute_router.paas_monitor[each.key].name
  region                             = each.key
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


resource "google_compute_firewall" "allow_iap_ssh" {
  name    = format("%s-allow-iap-ssh", google_compute_network.paas_monitor.name)
  network = google_compute_network.paas_monitor.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}
