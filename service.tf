resource "google_compute_backend_service" "paas-monitor" {
  name             = "paas-monitor-backend"
  description      = "region backend"
  protocol         = "HTTP"
  port_name        = "paas-monitor"
  timeout_sec      = 10
  session_affinity = "NONE"

  dynamic "backend" {
    for_each = local.regions
    content {
      group = module.instance-group[backend.key].instance_group_manager
    }
  }

  health_checks = [module.instance-group[tolist(local.regions)[0]].health_check]
}

module "instance-group" {
  for_each        = local.regions
  source          = "./backend"
  region          = each.key
  service_account = google_service_account.paas-monitor.email
}

resource "google_compute_firewall" "paas-monitor" {
  name    = "paas-monitor-firewall"
  network = "default"

  description = "allow Google health checks and network load balancers access"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["1337"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
  target_tags   = ["paas-monitor"]
}

resource "google_service_account" "paas-monitor" {
  account_id  = "paas-monitor"
  description = "the application showing it all"
}

resource "google_project_iam_member" "paas-monitor" {
  for_each = toset(["roles/logging.logWriter", "roles/monitoring.metricWriter"])
  member   = google_service_account.paas-monitor.member
  role     = each.key
  project  = google_service_account.paas-monitor.project
}

locals {
  regions = toset(["us-central1", "europe-west4", "asia-east1"])
}
