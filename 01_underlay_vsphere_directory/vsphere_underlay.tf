data "vsphere_datacenter" "dc" {
  name = var.vsphere_underlay.datacenter
}

resource "vsphere_folder" "esxi_folder" {
  path          = var.vsphere_underlay.folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}