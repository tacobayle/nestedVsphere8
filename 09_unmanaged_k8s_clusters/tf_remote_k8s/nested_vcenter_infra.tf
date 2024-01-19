data "vsphere_datacenter" "dc_nested" {
  name = var.vsphere_nested.datacenter
}

data "vsphere_datastore" "datastore_nested_masters" {
  count = length(var.unmanaged_k8s.masters_vsphere_datastore)
  name = var.unmanaged_k8s.masters_vsphere_datastore[count.index]
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_datastore" "datastore_nested_workers" {
  count = length(var.unmanaged_k8s.workers_vsphere_datastore)
  name = var.unmanaged_k8s.workers_vsphere_datastore[count.index]
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_resource_pool" "resource_pool_nested_masters" {
  count = length(var.unmanaged_k8s.masters_vsphere_cluster)
  name          = "${var.unmanaged_k8s.masters_vsphere_cluster[count.index]}/Resources"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_resource_pool" "resource_pool_nested_workers" {
  count = length(var.unmanaged_k8s.workers_vsphere_cluster)
  name          = "${var.unmanaged_k8s.workers_vsphere_cluster[count.index]}/Resources"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_network" "k8s_masters_networks" {
  count = length(var.unmanaged_k8s.masters_segments)
  name = var.unmanaged_k8s.masters_segments[count.index]
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_network" "k8s_workers_networks" {
  count = length(var.unmanaged_k8s.workers_segments)
  name = var.unmanaged_k8s.workers_segments[count.index]
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}
