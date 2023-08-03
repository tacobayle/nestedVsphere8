resource "vsphere_virtual_machine" "esxi_host_vsphere_alb_wo_nsx" {
  depends_on = [ vsphere_file.iso_upload ]
  count = (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") && var.vsphere_underlay.networks_vsphere_dual_attached == true  ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  name             = "${var.vsphere_nested.esxi.basename}${count.index + 1}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = "/${var.vsphere_underlay.datacenter}/vm/${var.vsphere_underlay.folder}"

  dynamic "network_interface" {
    for_each = data.vsphere_network.esxi_networks
    content {
      network_id = network_interface.value["id"]
    }
  }

  dynamic "network_interface" {
    for_each = data.vsphere_network.esxi_networks
    content {
      network_id = network_interface.value["id"]
    }
  }

    network_interface {
      network_id = data.vsphere_network.se[0].id
      ovf_mapping = "ens33"
    }

    network_interface {
      network_id = data.vsphere_network.backend[0].id
      ovf_mapping = "ens34"
    }

    network_interface {
      network_id = data.vsphere_network.vip[0].id
      ovf_mapping = "ens35"
    }

    network_interface {
      network_id = data.vsphere_network.tanzu[0].id
      ovf_mapping = "ens36"
    }

  num_cpus = var.vsphere_nested.esxi.cpu
  memory = var.vsphere_nested.esxi.memory
  guest_id = var.guest_id
  wait_for_guest_net_timeout = var.wait_for_guest_net_timeout
  nested_hv_enabled = var.nested_hv_enabled
  firmware = var.bios

  dynamic "disk" {
    for_each = var.vsphere_nested.esxi.disks
    content {
      size = disk.value["size"]
      label = "${var.vsphere_nested.esxi.basename}${count.index + 1}-${disk.value["label"]}.lab_vmdk"
      unit_number = disk.value["unit_number"]
      thin_provisioned = disk.value["thin_provisioned"]
    }
  }

  cdrom {
    datastore_id = data.vsphere_datastore.datastore.id
    path         = "isos/${basename(var.iso_location)}-${var.date_index}-${count.index}.iso"
  }
}


resource "vsphere_virtual_machine" "esxi_host_vsphere_alb_wo_nsx_single_attached" {
  depends_on = [ vsphere_file.iso_upload ]
  count = (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") && var.vsphere_underlay.networks_vsphere_dual_attached == false  ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  name             = "${var.vsphere_nested.esxi.basename}${count.index + 1}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = "/${var.vsphere_underlay.datacenter}/vm/${var.vsphere_underlay.folder}"

  dynamic "network_interface" {
    for_each = data.vsphere_network.esxi_networks
    content {
      network_id = network_interface.value["id"]
    }
  }

  network_interface {
    network_id = data.vsphere_network.vsphere_underlay_network_mgmt[0].id
  }

  network_interface {
    network_id = data.vsphere_network.se[0].id
    ovf_mapping = "ens33"
  }

  network_interface {
    network_id = data.vsphere_network.backend[0].id
    ovf_mapping = "ens34"
  }

  network_interface {
    network_id = data.vsphere_network.vip[0].id
    ovf_mapping = "ens35"
  }

  network_interface {
    network_id = data.vsphere_network.tanzu[0].id
    ovf_mapping = "ens36"
  }

  num_cpus = var.vsphere_nested.esxi.cpu
  memory = var.vsphere_nested.esxi.memory
  guest_id = var.guest_id
  wait_for_guest_net_timeout = var.wait_for_guest_net_timeout
  nested_hv_enabled = var.nested_hv_enabled
  firmware = var.bios

  dynamic "disk" {
    for_each = var.vsphere_nested.esxi.disks
    content {
      size = disk.value["size"]
      label = "${var.vsphere_nested.esxi.basename}${count.index + 1}-${disk.value["label"]}.lab_vmdk"
      unit_number = disk.value["unit_number"]
      thin_provisioned = disk.value["thin_provisioned"]
    }
  }

  cdrom {
    datastore_id = data.vsphere_datastore.datastore.id
    path         = "isos/${basename(var.iso_location)}-${var.date_index}-${count.index}.iso"
  }
}