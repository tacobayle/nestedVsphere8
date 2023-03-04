provider "vsphere" {
  user           = var.vsphere_underlay_username
  password       = var.vsphere_underlay_password
  vsphere_server = var.vcenter_underlay.server
  allow_unverified_ssl = true
}
