variable "region" {}

variable service_account {
  description = "The service account to use of the application."
  type        = string
  default     = ""
}

resource "google_compute_region_instance_group_manager" "paas-monitor" {
  name = "paas-monitor-${var.region}"

  base_instance_name = "paas-monitor-${var.region}"
  region             = var.region

  version {
    name              = "v1"
    instance_template = google_compute_instance_template.paas-monitor.self_link
  }

  named_port {
    name = "paas-monitor"
    port = 1337
  }

  auto_healing_policies {
    health_check      = google_compute_http_health_check.paas-monitor.self_link
    initial_delay_sec = 30
  }

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_surge_fixed                = 4
    max_unavailable_fixed          = 0
    replacement_method             = "SUBSTITUTE"
  }
}

resource "google_compute_instance_template" "paas-monitor" {
  description = "the paas-monitor backend application."

  tags = ["paas-monitor"]

  instance_description = "paas-monitor backend"
  machine_type         = "g1-small"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = false
    on_host_maintenance = "TERMINATE"
    preemptible         = true
  }

  disk {
    source_image = data.google_compute_image.cos_image.self_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = ""
    }
  }

  metadata = {
    startup-script = "docker run -d -p 1337:1337 -v /etc/ssl/certs:/etc/ssl/certs --env 'MESSAGE=gcp at ${var.region}'  gcr.io/binx-io-public/paas-monitor:4.0.0"
  }

  service_account {
    email = var.service_account
    scopes = [
      "cloud-platform"
    ]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_autoscaler" "paas-monitor" {
  name   = "paas-monitor-${var.region}"
  target = google_compute_region_instance_group_manager.paas-monitor.self_link

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }

  region = var.region
}

resource "google_compute_http_health_check" "paas-monitor" {
  name         = "paas-monitor-${var.region}"
  request_path = "/health"

  timeout_sec        = 5
  check_interval_sec = 5
  port               = 1337

  lifecycle {
    create_before_destroy = true
  }
}

data "google_compute_image" "cos_image" {
  family  = "cos-stable"
  project = "cos-cloud"
}

output "instance_group_manager" {
  value = google_compute_region_instance_group_manager.paas-monitor.instance_group
}

output "health_check" {
  value = google_compute_http_health_check.paas-monitor.self_link
}
