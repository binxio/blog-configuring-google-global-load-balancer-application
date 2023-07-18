resource "google_compute_global_forwarding_rule" "paas-monitor" {
  name       = "paas-monitor-port-80"
  target     = google_compute_target_http_proxy.paas-monitor.self_link
  ip_address = google_compute_global_address.paas-monitor.address
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "paas-monitor-ssl" {
  name       = "paas-monitor-port-443"
  target     = google_compute_target_https_proxy.paas-monitor.self_link
  ip_address = google_compute_global_address.paas-monitor.address
  port_range = "443"
}

resource "google_compute_target_http_proxy" "paas-monitor" {
  name    = "paas-monitor"
  url_map = google_compute_url_map.paas-monitor.self_link
}

resource "google_compute_url_map" "paas-monitor" {
  name        = "paas-monitor"
  description = "paas-monitor description"

  default_service = google_compute_backend_service.paas-monitor.self_link
}

resource "google_compute_global_address" "paas-monitor" {
  name = "paas-monitor"
}

resource "google_compute_global_address" "paas-monitor-ipv6" {
  name       = "paas-monitor-ipv6"
  ip_version = "IPV6"
}


resource "google_dns_record_set" "paas-monitor" {
  name = "paas-monitor.${google_dns_managed_zone.tld.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.tld.name

  rrdatas = ["${google_compute_global_address.paas-monitor.address}"]
}

resource "google_dns_record_set" "paas-monitor-aaaa" {
  name = "paas-monitor.${google_dns_managed_zone.tld.dns_name}"
  type = "AAAA"
  ttl  = 300

  managed_zone = google_dns_managed_zone.tld.name

  rrdatas = [google_compute_global_address.paas-monitor-ipv6.address]
}



resource "google_compute_managed_ssl_certificate" "paas-monitor" {
  name = "paas-monitor"

  managed {
    domains = ["paas-monitor.${google_dns_managed_zone.tld.dns_name}"]
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "google_compute_target_https_proxy" "paas-monitor" {
  name             = "paas-monitor"
  url_map          = google_compute_url_map.paas-monitor.id
  ssl_certificates = [google_compute_managed_ssl_certificate.paas-monitor.id]
}


output "ip-address" {
  value = google_compute_global_address.paas-monitor.address
}
