
resource "null_resource" "vcenter_install" {
  depends_on = [null_resource.esxi_customization_disk]

  provisioner "local-exec" {
    command = "/bin/bash 11_vCenter_iso_extract.sh"
  }
}

resource "null_resource" "wait_vsca" {
  depends_on = [null_resource.vcenter_install]

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${var.vcenter_underlay.networks.vsphere.management.vcenter_ip}); do echo \"Attempt $count: Waiting for vCenter to be reachable...\"; sleep 10 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to connect to vCenter\" ; exit 1 ; fi ; done"
  }
}

resource "null_resource" "vcenter_configure1" {
  depends_on = [null_resource.wait_vsca]

  provisioner "local-exec" {
    command = "/bin/bash 12_vCenter_config1.sh"
  }
}

resource "null_resource" "vcenter_migrating_vmk_to_vds" {
  depends_on = [null_resource.vcenter_configure1]

  provisioner "local-exec" {
    command = "ansible-playbook ansible/pb-vmk.yml --extra-vars @/root/nested_vsphere.json"
  }
}

resource "null_resource" "migrating_vmk0" {
  depends_on = [null_resource.vcenter_migrating_vmk_to_vds]
  count = length(var.vcenter_underlay.networks.vsphere.management.esxi_ips)
  connection {
    host        = var.vcenter_underlay.networks.vsphere.management.esxi_ips_temp[count.index]
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
      "esxcli network ip interface ipv4 set --interface-name=vmk0 --ipv4=${var.vcenter_underlay.networks.vsphere.management.esxi_ips[count.index]} --netmask=${var.vcenter_underlay.networks.vsphere.management.netmask} --type=static",
      "esxcli network ip interface tag add -i vmk0 -t Management",
      "esxcli network ip interface set -m 1500 -i vmk0",
      "esxcli network ip interface set -m ${var.networks.vds.mtu} -i vmk1",
      "esxcli network ip interface set -m ${var.networks.vds.mtu} -i vmk2"
    ]
  }
}

resource "null_resource" "cleaning_vmk3" {
  depends_on = [null_resource.migrating_vmk0]
  count = length(var.vcenter_underlay.networks.vsphere.management.esxi_ips)
  connection {
    host        = var.vcenter_underlay.networks.vsphere.management.esxi_ips[count.index]
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
  depends_on = [null_resource.cleaning_vmk3]

  provisioner "local-exec" {
    command = "/bin/bash 13_vCenter_config2.sh"
  }
}

resource "null_resource" "dual_uplink_update_multiple_vds" {
  depends_on = [null_resource.vcenter_configure2]
  count = length(var.vcenter_underlay.networks.vsphere.management.esxi_ips)
  connection {
    host        = var.vcenter_underlay.networks.vsphere.management.esxi_ips[count.index]
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


data "template_file" "expect_script" {
  template = file("${path.module}/templates/expect_script.sh.template")
  vars = {
    vcenter_username        = "administrator"
    vcenter_sso_domain = var.vcenter.sso.domain_name
    vsphere_nested_password = var.vsphere_nested_password
    vcenter_fqdn = "${var.vcenter.name}.${var.external_gw.bind.domain}"
    vcenter_dc = var.vcenter.datacenter
    vcenter_cluster = var.vcenter.cluster
  }
}


resource "null_resource" "execute_expect_script" {
  depends_on = [null_resource.dual_uplink_update_multiple_vds]
  connection {
    host        = var.vcenter_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    content = data.template_file.expect_script.rendered
    destination = "/tmp/vcenter_expect.sh"
  }


  provisioner "remote-exec" {
    inline      = [
      "chmod u+x /tmp/vcenter_expect.sh",
      "/tmp/vcenter_expect.sh"
    ]
  }
}