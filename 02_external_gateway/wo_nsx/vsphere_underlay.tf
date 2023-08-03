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

data "vsphere_network" "se" {
  count = var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0
  name = var.vsphere_underlay.networks.alb.se.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "backend" {
  count = var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0
  name = var.vsphere_underlay.networks.alb.backend.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "vip" {
  count = var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0

  name = var.vsphere_underlay.networks.alb.vip.name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "tanzu" {
  count = var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0
  name = var.vsphere_underlay.networks.alb.tanzu.name
  datacenter_id = data.vsphere_datacenter.dc.id
}


//data "vsphere_network" "vsphere_underlay_network_external" {
//  name = var.vsphere_underlay.networks.nsx.external.name
//  datacenter_id = data.vsphere_datacenter.dc.id
//}