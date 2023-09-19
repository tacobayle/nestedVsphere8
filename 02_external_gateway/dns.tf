resource "dns_a_record_set" "esxi" {
  depends_on = [null_resource.end, vsphere_virtual_machine.external_gw]
  count = length(var.vsphere_underlay.networks.vsphere.management.esxi_ips)
  zone  = "${var.external_gw.bind.domain}."
  name  = "${var.vsphere_nested.esxi.basename}${count.index + 1}"
  addresses = [element(var.vsphere_underlay.networks.vsphere.management.esxi_ips, count.index)]
  ttl = 60
}

resource "dns_ptr_record" "esxi" {
  depends_on = [null_resource.end, vsphere_virtual_machine.external_gw]
  count = length(var.vsphere_underlay.networks.vsphere.management.esxi_ips)
  zone = "${var.external_gw.bind.reverse}.in-addr.arpa."
  name = split(".", element(var.vsphere_underlay.networks.vsphere.management.esxi_ips, count.index))[3]
  ptr  = "${var.vsphere_nested.esxi.basename}${count.index + 1}.${var.external_gw.bind.domain}."
  ttl  = 60
}

resource "dns_a_record_set" "vcenter" {
  count = 1
  depends_on = [null_resource.end, vsphere_virtual_machine.external_gw]
  zone  = "${var.external_gw.bind.domain}."
  name  = var.vsphere_nested.vcsa_name
  addresses = [var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip]
  ttl = 60
}

resource "dns_cname_record" "vcenter_cname" {
  depends_on = [dns_a_record_set.vcenter]
  zone  = "${var.external_gw.bind.domain}."
  name  = "vcenter"
  cname = "${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}."
  ttl   = 300
}

resource "dns_ptr_record" "vcenter" {
  count = 1
  depends_on = [null_resource.end, vsphere_virtual_machine.external_gw]
  zone = "${var.external_gw.bind.reverse}.in-addr.arpa."
  name = split(".", var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip)[3]
  ptr  = "${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}."
  ttl  = 60
}

resource "dns_a_record_set" "nsx" {
  depends_on = [null_resource.end, vsphere_virtual_machine.external_gw]
  count = var.deployment == "vsphere_nsx" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd" || var.deployment == "vsphere_nsx_alb_telco" ? 1 : 0
  zone  = "${var.external_gw.bind.domain}."
  name  = var.external_gw.nsx_manager_name
  addresses = [var.vsphere_underlay.networks.vsphere.management.nsx_nested_ip]
  ttl = 60
}

resource "dns_ptr_record" "nsx" {
  count = var.deployment == "vsphere_nsx" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd" || var.deployment == "vsphere_nsx_alb_telco" ? 1 : 0
  depends_on = [null_resource.end, vsphere_virtual_machine.external_gw]
  zone = "${var.external_gw.bind.reverse}.in-addr.arpa."
  name = split(".", var.vsphere_underlay.networks.vsphere.management.nsx_nested_ip)[3]
  ptr  = "${var.external_gw.nsx_manager_name}.${var.external_gw.bind.domain}."
  ttl  = 60
}

resource "dns_a_record_set" "alb" {
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" || var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_alb_telco" ? 1 : 0
  depends_on = [null_resource.end, vsphere_virtual_machine.external_gw]
  zone  = "${var.external_gw.bind.domain}."
  name  = var.external_gw.alb_controller_name
  addresses = [var.vsphere_underlay.networks.vsphere.management.avi_nested_ip]
  ttl = 60
}

resource "dns_ptr_record" "alb" {
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" || var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_alb_telco" ? 1 : 0
  depends_on = [null_resource.end, vsphere_virtual_machine.external_gw]
  zone = "${var.external_gw.bind.reverse}.in-addr.arpa."
  name = split(".", var.vsphere_underlay.networks.vsphere.management.avi_nested_ip)[3]
  ptr  = "${var.external_gw.alb_controller_name}.${var.external_gw.bind.domain}."
  ttl  = 60
}

resource "dns_a_record_set" "vcd" {
  count = var.deployment == "vsphere_nsx_alb_vcd" ? 1 : 0
  depends_on = [null_resource.end, vsphere_virtual_machine.external_gw]
  zone  = "${var.external_gw.bind.domain}."
  name  = var.external_gw.vcd_appliance_name
  addresses = [var.vsphere_underlay.networks.vsphere.management.vcd_nested_ip]
  ttl = 60
}

resource "dns_ptr_record" "vcd" {
  count = var.deployment == "vsphere_nsx_alb_vcd" ? 1 : 0
  depends_on = [null_resource.end, vsphere_virtual_machine.external_gw]
  zone = "${var.external_gw.bind.reverse}.in-addr.arpa."
  name = split(".", var.vsphere_underlay.networks.vsphere.management.vcd_nested_ip)[3]
  ptr  = "${var.external_gw.vcd_appliance_name}.${var.external_gw.bind.domain}."
  ttl  = 60
}