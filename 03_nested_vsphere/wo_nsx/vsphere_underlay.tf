data "vsphere_datacenter" "dc" {
  name = var.vcenter_underlay.dc
}

data "vsphere_compute_cluster" "compute_cluster" {
  name          = var.vcenter_underlay.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name = var.vcenter_underlay.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vcenter_underlay.resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "esxi_networks" {
  count = length(values(var.vcenter_underlay.networks.vsphere))
  name = values(var.vcenter_underlay.networks.vsphere)[count.index].name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "vcenter_underlay_network_mgmt" {
  count = 1
  name = var.vcenter_underlay.networks.vsphere.management.name
  datacenter_id = data.vsphere_datacenter.dc.id
}
