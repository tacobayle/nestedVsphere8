data "vsphere_datacenter" "dc_nested" {
  name = var.vsphere_nested.datacenter
}

data "vsphere_compute_cluster" "compute_cluster_nested" {
  name          = var.vcd.cluster_ref
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_datastore" "datastore_nested" {
  name = "vsanDatastore"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_resource_pool" "resource_pool_nested" {
  name          = "${var.vcd.cluster_ref}/Resources"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_network" "vcenter_network_mgmt" {
  name = var.vcd_port_group_mgmt
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_network" "vcenter_network_db" {
  name = var.vcd_port_group_db
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}
