data "vsphere_datacenter" "dc_nested" {
  count            = 1
  name = var.vsphere_nested.datacenter
}

data "vsphere_host" "host_nested" {
  count = length(var.vsphere_underlay.networks.vsphere.management.esxi_ips)
  name          = "${var.vsphere_nested.esxi.basename}${count.index + 1}.${var.external_gw.bind.domain}"
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
}