resource "google_compute_backend_service" "paas-monitor" {
  name             = "paas-monitor-backend"
  description      = "region backend"
  protocol         = "HTTP"
  port_name        = "paas-monitor"
  timeout_sec      = 10
  session_affinity = "NONE"

  dynamic backend {
    for_each = local.regions
    content {
      group = module.instance-group[backend.key].instance_group_manager
    }
  }

  health_checks = [module.instance-group[tolist(local.regions)[0]].health_check]
}

module "instance-group" {
  for_each = local.regions
  source = "./backend"
  region = each.key
  service_account = google_service_account.paas-monitor.email
}

moved {
  from = module.instance-group-region-a
  to  = module.instance-group["us-central1"]
}

moved {
  from = module.instance-group-region-b
  to  = module.instance-group["europe-west4"]
}

moved {
  from = module.instance-group-region-c
  to  = module.instance-group["asia-east1"]
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
  account_id = "paas-monitor"
  description = "the application showing it all"
}

resource "google_project_iam_member" "paas-monitor" {
  for_each = toset(["roles/logging.logWriter", "roles/monitoring.metricWriter"])
  member = google_service_account.paas-monitor.member
  role = each.key
  project = google_service_account.paas-monitor.project
}

resource "google_secret_manager_secret" "paas-monitor-identity" {
  secret_id = "paas-monitor-identity"

  replication {
    user_managed {
      dynamic replicas {
        for_each = local.regions
        content {
          location = replicas.key
        }
      }
    }
  }
}

resource google_secret_manager_secret_iam_binding "paas-monitor-identity-accessors" {
  secret_id = google_secret_manager_secret.paas-monitor-identity.secret_id
  role = "roles/secretmanager.secretAccessor"
  members = [
    google_service_account.paas-monitor.member
  ]
}

locals {
  regions = toset(["us-central1", "europe-west4", "asia-east1"])
}
