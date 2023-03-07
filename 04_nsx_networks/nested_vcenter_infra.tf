data "vsphere_datacenter" "dc_nested" {
  count            = 1
  name = var.vcenter.datacenter
}

data "vsphere_host" "host_nested" {
  count = length(var.vcenter_underlay.networks.vsphere.management.esxi_ips)
  name          = "${var.vcenter.esxi.basename}${count.index + 1}.${var.external_gw.bind.domain}"
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
}

resource "vsphere_distributed_virtual_switch" "network_nsx_external" {
  count = 1
  name = var.networks.nsx.nsx_external.name
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
  version = var.vds_version
  max_mtu = var.networks.nsx.nsx_external.max_mtu

  dynamic "host" {
    for_each = data.vsphere_host.host_nested
    content {
      host_system_id = host.value.id
      devices        = ["vmnic6"]
    }
  }
}

resource "vsphere_distributed_port_group" "pg_nsx_external" {
  count = 1
  name                            = var.networks.nsx.nsx_external.port_group_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.network_nsx_external[0].id
  vlan_id = 0
}

resource "vsphere_distributed_virtual_switch" "network_nsx_overlay" {
  count = 1
  name = var.networks.nsx.nsx_overlay.name
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
  version = var.vds_version
  max_mtu = var.networks.nsx.nsx_overlay.max_mtu

  dynamic "host" {
    for_each = data.vsphere_host.host_nested
    content {
      host_system_id = host.value.id
      devices        = ["vmnic7"]
    }
  }
}

resource "vsphere_distributed_port_group" "pg_nsx_overlay" {
  count = 1
  name                            = var.networks.nsx.nsx_overlay.port_group_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.network_nsx_overlay[0].id
  vlan_id = 0
}

resource "vsphere_distributed_virtual_switch" "network_nsx_overlay_edge" {
  count = 1
  name = var.networks.nsx.nsx_overlay_edge.name
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
  version = var.vds_version
  max_mtu = var.networks.nsx.nsx_overlay_edge.max_mtu

  dynamic "host" {
    for_each = data.vsphere_host.host_nested
    content {
      host_system_id = host.value.id
      devices        = ["vmnic8"]
    }
  }
}

resource "vsphere_distributed_port_group" "pg_nsx_overlay_edge" {
  count = 1
  name                            = var.networks.nsx.nsx_overlay_edge.port_group_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.network_nsx_overlay_edge[0].id
  vlan_id = 0
}