provider "vsphere" {
  user           = "administrator@${var.vsphere_nested.sso.domain_name}"
  password       = var.vsphere_nested_password
  vsphere_server = "${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
  allow_unverified_ssl = true
}

provider "nsxt" {
  host                     = var.vsphere_underlay.networks.vsphere.management.nsx_nested_ip
  username                 = "admin"
  password                 = var.nsx_password
  allow_unverified_ssl     = true
  max_retries              = 10
  retry_min_delay          = 500
  retry_max_delay          = 5000
  retry_on_status_codes    = [429]
}