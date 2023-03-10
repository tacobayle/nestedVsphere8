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


data "vsphere_network" "vcenter_network_mgmt_nested" {
  name = var.networks.vsphere.management.port_group_name
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}