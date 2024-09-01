data "vsphere_datacenter" "dc" {
  name = var.vsphere_underlay.datacenter
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vsphere_underlay.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name = var.vsphere_underlay.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = "${var.vsphere_underlay.cluster}/Resources"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "vsphere_underlay_network_mgmt" {
  name = var.vsphere_underlay.networks.vsphere.management.name
  datacenter_id = data.vsphere_datacenter.dc.id
}