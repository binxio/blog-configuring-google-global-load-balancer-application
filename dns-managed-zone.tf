resource "google_dns_managed_zone" "tld" {
  name        = replace(var.domain-name, ".", "-")
  dns_name    = "${var.domain-name}."
  description = "top level domain name for the paas-monitor ${var.domain-name}"
}

output "tld-name-servers" {
  value = google_dns_managed_zone.tld.name_servers
}
