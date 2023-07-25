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

resource "vsphere_folder" "se_groups_folders" {
  count = length(var.avi.config.cloud.service_engine_groups)
  path          = "${var.avi.config.seg_folder_basename}-${var.avi.config.cloud.service_engine_groups[count.index].name}"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}