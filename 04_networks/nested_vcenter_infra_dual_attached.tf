

resource "vsphere_distributed_virtual_switch" "network_nsx_external" {
  count = (var.vsphere_underlay.networks_vsphere_dual_attached == true) && (var.deployment == "vsphere_nsx" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_alb_telco" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd") ? 1 : 0
  name = var.networks.nsx.nsx_external.vds_name
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
  count = (var.vsphere_underlay.networks_vsphere_dual_attached == true) && (var.deployment == "vsphere_nsx" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_alb_telco" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd") ? 1 : 0
  name                            = var.networks.nsx.nsx_external.port_group_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.network_nsx_external[0].id
  vlan_id = 0
}

resource "vsphere_distributed_virtual_switch" "network_nsx_overlay" {
  count = (var.vsphere_underlay.networks_vsphere_dual_attached == true) && (var.deployment == "vsphere_nsx" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_telco" || var.deployment == "vsphere_nsx_alb_vcd") ? 1 : 0
  name = var.networks.nsx.nsx_overlay.vds_name
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
  count = (var.vsphere_underlay.networks_vsphere_dual_attached == true) && (var.deployment == "vsphere_nsx" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_alb_telco" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd") ? 1 : 0
  name                            = var.networks.nsx.nsx_overlay.port_group_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.network_nsx_overlay[0].id
  vlan_id = 0
}

resource "vsphere_distributed_virtual_switch" "network_nsx_overlay_edge" {
  count = (var.vsphere_underlay.networks_vsphere_dual_attached == true) && (var.deployment == "vsphere_nsx" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_alb_telco" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd") ? 1 : 0
  name = var.networks.nsx.nsx_overlay_edge.vds_name
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
  count = (var.vsphere_underlay.networks_vsphere_dual_attached == true) && (var.deployment == "vsphere_nsx" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_alb_telco" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd") ? 1 : 0
  name                            = var.networks.nsx.nsx_overlay_edge.port_group_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.network_nsx_overlay_edge[0].id
  vlan_id = 0
}

resource "vsphere_distributed_virtual_switch" "alb_se" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true && (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") ? 1 : 0
  name = var.networks.alb.se.name
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
  version = var.vds_version
  max_mtu = var.networks.alb.se.max_mtu

  dynamic "host" {
    for_each = data.vsphere_host.host_nested
    content {
      host_system_id = host.value.id
      devices        = ["vmnic6"]
    }
  }
}

resource "vsphere_distributed_port_group" "pg_alb_se" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true && (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") ? 1 : 0
  name                            = var.networks.alb.se.port_group_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.alb_se[0].id
  vlan_id = 0
}

resource "vsphere_distributed_virtual_switch" "alb_backend" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true && (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") ? 1 : 0
  name = var.networks.alb.backend.name
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
  version = var.vds_version
  max_mtu = var.networks.alb.backend.max_mtu

  dynamic "host" {
    for_each = data.vsphere_host.host_nested
    content {
      host_system_id = host.value.id
      devices        = ["vmnic7"]
    }
  }
}

resource "vsphere_distributed_port_group" "pg_alb_backend" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true && (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") ? 1 : 0
  name                            = var.networks.alb.backend.port_group_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.alb_backend[0].id
  vlan_id = 0
}

resource "vsphere_distributed_virtual_switch" "alb_vip" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true && (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") ? 1 : 0
  name = var.networks.alb.vip.name
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
  version = var.vds_version
  max_mtu = var.networks.alb.vip.max_mtu

  dynamic "host" {
    for_each = data.vsphere_host.host_nested
    content {
      host_system_id = host.value.id
      devices        = ["vmnic8"]
    }
  }
}

resource "vsphere_distributed_port_group" "pg_alb_vip" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true && (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") ? 1 : 0
  name                            = var.networks.alb.vip.port_group_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.alb_vip[0].id
  vlan_id = 0
}

resource "vsphere_distributed_virtual_switch" "alb_tanzu" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true && (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") ? 1 : 0
  name = var.networks.alb.tanzu.name
  datacenter_id = data.vsphere_datacenter.dc_nested[0].id
  version = var.vds_version
  max_mtu = var.networks.alb.tanzu.max_mtu

  dynamic "host" {
    for_each = data.vsphere_host.host_nested
    content {
      host_system_id = host.value.id
      devices        = ["vmnic9"]
    }
  }
}

resource "vsphere_distributed_port_group" "pg_alb_tanzu" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true && (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") ? 1 : 0
  name                            = var.networks.alb.tanzu.port_group_name
  distributed_virtual_switch_uuid = vsphere_distributed_virtual_switch.alb_tanzu[0].id
  vlan_id = 0
}