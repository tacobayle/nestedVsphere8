resource "dns_a_record_set" "esxi" {
  depends_on = [null_resource.end]
  count = length(var.vsphere_underlay.networks.vsphere.management.esxi_ips)
  zone  = "${var.external_gw.bind.domain}."
  name  = "${var.vsphere_nested.esxi.basename}${count.index + 1}"
  addresses = [element(var.vsphere_underlay.networks.vsphere.management.esxi_ips, count.index)]
  ttl = 60
}

resource "dns_a_record_set" "nsx" {
  depends_on = [null_resource.end]
  count = 1
  zone  = "${var.external_gw.bind.domain}."
  name  = "nsx-manager"
  addresses = [var.vsphere_underlay.networks.vsphere.management.nsx_nested_ip]
  ttl = 60
}

resource "dns_cname_record" "nsx_cname" {
  depends_on = [dns_a_record_set.nsx, null_resource.end]
  zone  = "${var.external_gw.bind.domain}."
  name  = "nsx"
  cname = "nsx-manager.${var.external_gw.bind.domain}."
  ttl   = 300
}

resource "dns_ptr_record" "esxi" {
  depends_on = [null_resource.end]
  count = length(var.vsphere_underlay.networks.vsphere.management.esxi_ips)
  zone = "${var.external_gw.bind.reverse}.in-addr.arpa."
  name = split(".", element(var.vsphere_underlay.networks.vsphere.management.esxi_ips, count.index))[3]
  ptr  = "${var.vsphere_nested.esxi.basename}${count.index + 1}.${var.external_gw.bind.domain}."
  ttl  = 60
}

resource "dns_a_record_set" "vcenter" {
  count = 1
  depends_on = [null_resource.end]
  zone  = "${var.external_gw.bind.domain}."
  name  = var.vsphere_nested.vcsa_name
  addresses = [var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip]
  ttl = 60
}

resource "dns_cname_record" "vcenter_cname" {
  depends_on = [dns_a_record_set.vcenter, null_resource.end]
  zone  = "${var.external_gw.bind.domain}."
  name  = "vcenter"
  cname = "${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}."
  ttl   = 300
}

resource "dns_ptr_record" "vcenter" {
  count = 1
  depends_on = [null_resource.end]
  zone = "${var.external_gw.bind.reverse}.in-addr.arpa."
  name = split(".", var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip)[3]
  ptr  = "${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}."
  ttl  = 60
}



resource "dns_a_record_set" "vcd" {
  count = var.external_gw.vcd_deployment == true ? 1 : 0
  depends_on = [null_resource.end]
  zone  = "${var.external_gw.bind.domain}."
  name  = "vcd"
  addresses = [var.vsphere_underlay.networks.vsphere.management.vcd_nested_ip]
  ttl = 60
}

resource "dns_ptr_record" "vcd" {
  count = var.external_gw.vcd_deployment == true ? 1 : 0
  depends_on = [null_resource.end]
  zone = "${var.external_gw.bind.reverse}.in-addr.arpa."
  name = split(".", var.vsphere_underlay.networks.vsphere.management.vcd_nested_ip)[3]
  ptr  = "vcd.${var.external_gw.bind.domain}."
  ttl  = 60
}

