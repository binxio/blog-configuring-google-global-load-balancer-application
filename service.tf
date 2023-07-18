resource "google_compute_backend_service" "paas-monitor" {
  name             = "paas-monitor-backend"
  description      = "region backend"
  protocol         = "HTTP"
  port_name        = "paas-monitor"
  timeout_sec      = 10
  session_affinity = "NONE"

  backend {
    group = module.instance-group-region-a.instance_group_manager
  }

  backend {
    group = module.instance-group-region-b.instance_group_manager
  }

  backend {
    group = module.instance-group-region-c.instance_group_manager
  }

  health_checks = ["${module.instance-group-region-a.health_check}"]
}

module "instance-group-region-a" {
  source = "./backend"
  region = "us-central1"
}

module "instance-group-region-b" {
  source = "./backend"
  region = "europe-west4"
}

module "instance-group-region-c" {
  source = "./backend"
  region = "asia-east1"
}

resource "google_compute_firewall" "paas-monitor" {
  ## firewall rules enabling the load balancer health checks
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

