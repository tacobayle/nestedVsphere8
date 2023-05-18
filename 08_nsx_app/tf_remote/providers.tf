provider "vsphere" {
  user           = "administrator@${var.vsphere_nested.sso.domain_name}"
  password       = var.vsphere_nested_password
  vsphere_server = "${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
  allow_unverified_ssl = true
}