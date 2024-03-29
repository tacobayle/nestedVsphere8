data "vsphere_datacenter" "dc_nested" {
  name = var.vsphere_nested.datacenter
}

data "vsphere_datastore" "datastore_nested" {
  name = var.vsphere_nested.datastore_list[0]
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_resource_pool" "resource_pool_nested" {
  name          = "${var.vsphere_nested.cluster_list[0]}/Resources"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_network" "app" {
  count = length(var.app_segments)
  name = var.app_segments[count.index]
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_network" "app_vpc" {
  count = length(var.app_segments_vpc)
  name = var.app_segments_vpc[count.index]
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}
