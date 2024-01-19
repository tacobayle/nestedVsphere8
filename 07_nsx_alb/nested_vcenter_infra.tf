data "vsphere_datacenter" "dc_nested" {
  name = var.vsphere_nested.datacenter
}

data "vsphere_datastore" "datastore_nested" {
  name = var.avi.datastore_ref
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_resource_pool" "resource_pool_nested" {
  name          = "${var.avi.cluster_ref}/Resources"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}


data "vsphere_network" "vcenter_network_mgmt_nested" {
  name = var.avi_port_group
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}