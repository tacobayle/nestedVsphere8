

// dual attached scenario

resource "null_resource" "vcenter_configure1_dual_attached" {
  depends_on = [null_resource.wait_vsca]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true ? 1 : 0
  provisioner "local-exec" {
    command = "/bin/bash 12_vCenter_config1.sh"
  }
}

resource "null_resource" "vcenter_migrating_vmk_to_vds" {
  depends_on = [null_resource.vcenter_configure1_dual_attached]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true ? 1 : 0
  provisioner "local-exec" {
    command = "ansible-playbook ansible/pb-vmk.yml --extra-vars @/root/nested_vsphere.json"
  }
}

resource "null_resource" "migrating_vmk0" {
  depends_on = [null_resource.vcenter_migrating_vmk_to_vds]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.esxi_ips_temp[count.index]
    type        = "ssh"
    agent       = false
    user        = "root"
    password    = var.nested_esxi_root_password
  }

  provisioner "remote-exec" {
    inline      = [
      "portid=$(esxcfg-vswitch -l |grep vmk4 |awk '{print $1}')",
      "esxcli network ip interface remove --interface-name=vmk0",
      "esxcli network ip interface remove --interface-name=vmk4",
      "esxcli network ip interface add --interface-name=vmk0 --dvs-name=${var.networks.vsphere.management.vds_name} --dvport-id=$portid",
      "esxcli network ip interface ipv4 set --interface-name=vmk0 --ipv4=${var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index]} --netmask=${var.vsphere_underlay.networks.vsphere.management.netmask} --type=static",
      "esxcli network ip interface tag add -i vmk0 -t Management",
      "esxcli network ip interface set -m 1500 -i vmk0",
      "esxcli network ip interface set -m ${var.networks.vds.mtu} -i vmk1",
      "esxcli network ip interface set -m ${var.networks.vds.mtu} -i vmk2"
    ]
  }
}


resource "null_resource" "cleaning_vmk3" {
  depends_on = [null_resource.migrating_vmk0]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index]
    type        = "ssh"
    agent       = false
    user        = "root"
    password    = var.nested_esxi_root_password
  }

  provisioner "remote-exec" {
    inline      = [
      "esxcli network ip interface remove --interface-name=vmk3"
    ]
  }
}

resource "null_resource" "vcenter_configure2" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true ? 1 : 0
  depends_on = [null_resource.cleaning_vmk3]

  provisioner "local-exec" {
    command = "/bin/bash 13_vCenter_config2.sh"
  }
}

resource "null_resource" "dual_uplink_update_multiple_vds" {
  depends_on = [null_resource.vcenter_configure2]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index]
    type        = "ssh"
    agent       = false
    user        = "root"
    password    = var.nested_esxi_root_password
  }

  provisioner "remote-exec" {
    inline      = [
      "esxcli network vswitch standard uplink remove -u vmnic4 -v vSwitch1",
      "esxcli network vswitch standard uplink remove -u vmnic5 -v vSwitch2",
      "portid=$(esxcfg-vswitch -l | grep -A4 ${var.networks.vsphere.management.vds_name} | grep -A2 DVPort | grep -A1 vmnic0 | grep -v vmnic0 |awk '{print $1}')",
      "esxcfg-vswitch -P vmnic3 -V $portid ${var.networks.vsphere.management.vds_name}",
      "portid=$(esxcfg-vswitch -l | grep -A4 ${var.networks.vsphere.VMotion.vds_name} | grep -A2 DVPort | grep -A1 vmnic1 | grep -v vmnic1 |awk '{print $1}')",
      "esxcfg-vswitch -P vmnic4 -V $portid ${var.networks.vsphere.VMotion.vds_name}",
      "portid=$(esxcfg-vswitch -l | grep -A4 ${var.networks.vsphere.VSAN.vds_name} | grep -A2 DVPort | grep -A1 vmnic2 | grep -v vmnic2 |awk '{print $1}')",
      "esxcfg-vswitch -P vmnic5 -V $portid ${var.networks.vsphere.VSAN.vds_name}"
    ]
  }
}