data "vsphere_datacenter" "dc_nested" {
  count            = 1
  name = var.vsphere_nested.datacenter
}

data "vsphere_compute_cluster" "compute_cluster_nested" {
  count            = 1
  name          = var.vsphere_nested.cluster
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
}

data "vsphere_datastore" "datastore_nested" {
  count            = 1
  name = "vsanDatastore"
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
}

data "vsphere_resource_pool" "resource_pool_nested" {
  count            = 1
  name          = "${var.vsphere_nested.cluster}/Resources"
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
}

data "vsphere_network" "vcenter_network_mgmt_nested" {
  count = 1
  name = var.avi_segment
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
}

data "vsphere_network" "networks_app" {
  count = length(var.app_segments)
  name = var.avi_segment[count.index]
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
}

resource "vsphere_content_library" "nested_library_avi" {
  count = 1
  name            = "avi_controller"
  storage_backing = [data.vsphere_datastore.datastore_nested[0].id]
  description     = "avi_controller"
}

resource "vsphere_content_library_item" "nested_library_avi_item" {
  count = 1
  name        = "avi.ova"
  description = "avi.ova"
  library_id  = vsphere_content_library.nested_library_avi[0].id
  file_url = "/home/ubuntu/${basename(var.avi_ova_path)}"
}

resource "vsphere_content_library" "nested_library_avi_app" {
  name            = "avi_app"
  storage_backing = [data.vsphere_datastore.datastore_nested.id]
}

resource "vsphere_content_library_item" "nested_library_item_avi_app" {
  name        = "ubuntu.ova"
  library_id  = vsphere_content_library.nested_library_avi_app.id
  file_url = "/hone/ubuntu/${basename(var.ubuntu_ova_path)}"
}