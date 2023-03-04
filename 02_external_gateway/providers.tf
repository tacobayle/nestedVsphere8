provider "vsphere" {
  user           = var.vsphere_underlay_username
  password       = var.vsphere_underlay_password
  vsphere_server = var.vcenter_underlay.server
  allow_unverified_ssl = true
}

provider "dns" {
  update {
    server        = var.vcenter_underlay.networks.vsphere.management.external_gw_ip
    key_name      = "myKeyName."
    key_algorithm = "hmac-md5"
    key_secret    = base64encode(var.bind_password)
  }
}