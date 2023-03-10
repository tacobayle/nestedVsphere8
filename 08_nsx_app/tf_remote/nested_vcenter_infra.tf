data "vsphere_datacenter" "dc_nested" {
  name = var.vsphere_nested.datacenter
}

data "vsphere_compute_cluster" "compute_cluster_nested" {
  name          = var.vsphere_nested.cluster
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_datastore" "datastore_nested" {
  name = "vsanDatastore"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_resource_pool" "resource_pool_nested" {
  name          = "${var.vsphere_nested.cluster}/Resources"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_network" "app" {
  count = length(var.app_segments)
  name = var.app_segments[count.index]
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

