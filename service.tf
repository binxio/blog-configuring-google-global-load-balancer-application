
module "instance-group" {
  for_each        = local.regions
  source          = "./backend"
  region          = each.key
  subnetwork      = google_compute_subnetwork.paas_monitor[each.key].id
  service_account = google_service_account.paas-monitor.email
  ziti_identity   = "${google_secret_manager_secret.paas-monitor-identity.name}/versions/latest"
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

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
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

resource "google_secret_manager_secret" "paas-monitor-identity" {
  secret_id = "paas-monitor-identity"

  replication {
    user_managed {
      dynamic "replicas" {
        for_each = local.secret_regions
        content {
          location = replicas.key
        }
      }
    }
  }
}

resource "google_secret_manager_secret_iam_binding" "paas-monitor-identity-accessors" {
  secret_id = google_secret_manager_secret.paas-monitor-identity.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    google_service_account.paas-monitor.member
  ]
}

locals {
  secret_regions = toset(["us-central1", "europe-west4", "asia-east1"])
  regions = {
    "us-central1"  = "10.0.0.0/24",
    "europe-west4" = "10.0.1.0/24"
    "asia-east1"   = "10.0.2.0/24"
  }
}
