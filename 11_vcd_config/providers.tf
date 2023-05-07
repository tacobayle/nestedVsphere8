provider "vcd" {
  user     = "administrator"
  password = var.vcd_administrator_password
  org      = "System"
  url      = "https://${var.vsphere_underlay.networks.vsphere.management.vcd_nested_ip}/api"
  allow_unverified_ssl = true
}