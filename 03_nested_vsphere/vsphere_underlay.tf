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

data "vsphere_network" "esxi_networks" {
  count = length(values(var.vsphere_underlay.networks.vsphere))
  name = values(var.vsphere_underlay.networks.vsphere)[count.index].name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "vsphere_underlay_network_mgmt" {
  count = 1
  name = var.vsphere_underlay.networks.vsphere.management.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network_nsx_external" {
  count = 1
  name = var.vsphere_underlay.networks.nsx.external.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network_nsx_overlay" {
  count = 1
  name = var.vsphere_underlay.networks.nsx.overlay.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network_nsx_overlay_edge" {
  count = 1
  name = var.vsphere_underlay.networks.nsx.overlay_edge.name
  datacenter_id = data.vsphere_datacenter.dc.id
}