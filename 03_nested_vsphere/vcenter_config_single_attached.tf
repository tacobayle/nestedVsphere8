
// single attached scenario

resource "null_resource" "vcenter_configure1_single_attached" {
  depends_on = [null_resource.wait_vsca]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  provisioner "local-exec" {
    command = "/bin/bash 12_vCenter_config1_single_attached.sh"
  }
}

resource "null_resource" "vcenter_adding_vmk3_and_vmk4_to_vds_single_attached" {
  depends_on = [null_resource.vcenter_configure1_single_attached]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  provisioner "local-exec" {
    command = "ansible-playbook ansible/pb-vmk-mgmt.yml --extra-vars @/root/nested_vsphere.json"
  }
}

resource "null_resource" "migrating_vmk0_single_attached" {
  depends_on = [null_resource.vcenter_adding_vmk3_and_vmk4_to_vds_single_attached]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
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
      "esxcli network ip interface set -m ${var.networks.vds.mtu} -i vmk0",
    ]
  }
}

resource "null_resource" "cleaning_vmk3_single_attached" {
  depends_on = [null_resource.migrating_vmk0_single_attached]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
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

resource "null_resource" "vcenter_delete_vswitch_management" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  depends_on = [null_resource.cleaning_vmk3_single_attached]

  provisioner "local-exec" {
    command = "/bin/bash 13_esxi_delete_vswitch_management.sh"
  }
}

resource "null_resource" "migrating_mgmt_vds_uplink" {
  depends_on = [null_resource.vcenter_delete_vswitch_management]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index]
    type        = "ssh"
    agent       = false
    user        = "root"
    password    = var.nested_esxi_root_password
  }

  provisioner "remote-exec" {
    inline      = [
      "portid=$(esxcfg-vswitch -l | grep -A4 ${var.networks.vsphere.management.vds_name} | grep -A2 DVPort | grep -A1 vmnic3  | grep -v vmnic3 |awk '{print $1}')",
      "esxcfg-vswitch -P vmnic0 -V $portid ${var.networks.vsphere.management.vds_name}",
      "portid=$(esxcfg-vswitch -l | grep -A4 ${var.networks.vsphere.management.vds_name} | grep -A2 DVPort | grep vmnic3 | awk '{print $1}' )",
      "esxcfg-vswitch -Q vmnic3 -V $portid ${var.networks.vsphere.management.vds_name}"
    ]
  }
}

resource "null_resource" "shutdown_vcsa_vcsa" {
  depends_on = [null_resource.migrating_mgmt_vds_uplink]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.esxi_ips[0]
    type        = "ssh"
    agent       = false
    user        = "root"
    password    = var.nested_esxi_root_password
  }

  provisioner "remote-exec" {
    inline      = [
      "vim-cmd vmsvc/power.shutdown 1",
      "count=1 ; while [ $(vim-cmd vmsvc/power.getstate 1 | tail -1 | awk '{print $2}') != \"off\" ] ; do echo \"Attempt $count: Waiting for VCSA to be shutdown\"; sleep 40 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to get VCSA poweredOff\" ; exit 1 ; fi ; done"
    ]
  }
}

resource "null_resource" "restart_esxi_vsphere_wo_nsx" {
  depends_on = [null_resource.shutdown_vcsa_vcsa]
  count = var.deployment == "vsphere_wo_nsx" && var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vsphere_underlay.datacenter}
      export GOVC_URL=${var.vsphere_underlay.vcsa}
      export GOVC_CLUSTER=${var.vsphere_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.power -s -vm.uuid ${vsphere_virtual_machine.esxi_host_single_attached[count.index].uuid}
      count=1 ; while [ $(/usr/local/bin/govc vm.info  -vm.uuid ${vsphere_virtual_machine.esxi_host_single_attached[count.index].uuid} | grep "Power state:" | awk '{print $3}') != "poweredOff" ] ; do echo \"Attempt $count: Waiting for ESXi host ${count.index} to be poweredOff...\"; sleep 40 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to get ESXi host ${count.index} poweredOff\" ; exit 1 ; fi ; done
      /usr/local/bin/govc vm.power -on -vm.uuid ${vsphere_virtual_machine.esxi_host_single_attached[count.index].uuid}
    EOT
  }
}

resource "null_resource" "restart_esxi_vsphere_alb_wo_nsx" {
  depends_on = [null_resource.shutdown_vcsa_vcsa]
  count = (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") && var.vsphere_underlay.networks_vsphere_dual_attached == false  ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vsphere_underlay.datacenter}
      export GOVC_URL=${var.vsphere_underlay.vcsa}
      export GOVC_CLUSTER=${var.vsphere_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.power -s -vm.uuid ${vsphere_virtual_machine.esxi_host_vsphere_alb_wo_nsx_single_attached[count.index].uuid}
      count=1 ; while [ $(/usr/local/bin/govc vm.info  -vm.uuid ${vsphere_virtual_machine.esxi_host_vsphere_alb_wo_nsx_single_attached[count.index].uuid} | grep "Power state:" | awk '{print $3}') != "poweredOff" ] ; do echo \"Attempt $count: Waiting for ESXi host ${count.index} to be poweredOff...\"; sleep 40 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to get ESXi host ${count.index} poweredOff\" ; exit 1 ; fi ; done
      /usr/local/bin/govc vm.power -on -vm.uuid ${vsphere_virtual_machine.esxi_host_vsphere_alb_wo_nsx_single_attached[count.index].uuid}
    EOT
  }
}

resource "null_resource" "restart_esxi_nsx" {
  depends_on = [null_resource.shutdown_vcsa_vcsa]
  count = (var.deployment == "vsphere_nsx" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_alb_telco" || var.deployment == "vsphere_nsx_alb_vcd") && var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vsphere_underlay.datacenter}
      export GOVC_URL=${var.vsphere_underlay.vcsa}
      export GOVC_CLUSTER=${var.vsphere_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.power -s -vm.uuid ${vsphere_virtual_machine.esxi_host_nsx_single_attached[count.index].uuid}
      count=1 ; while [ $(/usr/local/bin/govc vm.info  -vm.uuid ${vsphere_virtual_machine.esxi_host_nsx_single_attached[count.index].uuid} | grep "Power state:" | awk '{print $3}') != "poweredOff" ] ; do echo \"Attempt $count: Waiting for ESXi host ${count.index} to be poweredOff...\"; sleep 40 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to get ESXi host ${count.index} poweredOff\" ; exit 1 ; fi ; done
      /usr/local/bin/govc vm.power -on -vm.uuid ${vsphere_virtual_machine.esxi_host_nsx_single_attached[count.index].uuid}
    EOT
  }
}

resource "null_resource" "wait_esxi_after_esxi_restart" {
  depends_on = [null_resource.restart_esxi_nsx, null_resource.restart_esxi_vsphere_alb_wo_nsx, null_resource.restart_esxi_vsphere_wo_nsx]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index]}); do echo \"Attempt $count: Waiting for ESXi host ${count.index} to be reachable...\"; sleep 40 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to connect to ESXi host\" ; exit 1 ; fi ; done"
  }
}

resource "time_sleep" "wait_before_restart_vcsa" {
  depends_on = [null_resource.wait_esxi_after_esxi_restart]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  create_duration = "60s"
}

resource "null_resource" "restart_vcsa" {
  depends_on = [time_sleep.wait_before_restart_vcsa]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.esxi_ips[0]
    type        = "ssh"
    agent       = false
    user        = "root"
    password    = var.nested_esxi_root_password
  }

  provisioner "remote-exec" {
    inline      = [
      "vim-cmd vmsvc/power.on 1"
    ]
  }
}

resource "null_resource" "wait_vsca_after_esxi_restart" {
  depends_on = [null_resource.restart_vcsa]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip}); do echo \"Attempt $count: Waiting for vCenter to be reachable...\"; sleep 10 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to connect to vCenter\" ; exit 1 ; fi ; done"
  }
}

resource "null_resource" "test_vcenter_health" {
  depends_on = [null_resource.wait_vsca_after_esxi_restart]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0

  provisioner "local-exec" {
    command = "/bin/bash test_vcenter_health.sh"
  }
}

resource "null_resource" "adding_vmotion_vds_uplink_temporary" {
  depends_on = [null_resource.test_vcenter_health]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  provisioner "local-exec" {
    command = "/bin/bash 14_vCenter_adding_uplink_vmotion.sh"
  }
}

resource "null_resource" "migrating_vmk_vmotion" {
  depends_on = [null_resource.adding_vmotion_vds_uplink_temporary]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  provisioner "local-exec" {
    command = "ansible-playbook ansible/pb-vmk-vmotion.yml --extra-vars @/root/nested_vsphere.json"
  }
}

resource "null_resource" "delete_vswitch_vmotion" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  depends_on = [null_resource.migrating_vmk_vmotion]
  provisioner "local-exec" {
    command = "/bin/bash 15_esxi_delete_vswitch_vmotion.sh"
  }
}

resource "null_resource" "migrating_vmotion_vds_uplink" {
  depends_on = [null_resource.delete_vswitch_vmotion]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index]
    type        = "ssh"
    agent       = false
    user        = "root"
    password    = var.nested_esxi_root_password
  }

  provisioner "remote-exec" {
    inline      = [
      "portid=$(esxcfg-vswitch -l | grep -A4 ${var.networks.vsphere.VMotion.vds_name} | grep -A2 DVPort | grep -A1 vmnic3  | grep -v vmnic3 |awk '{print $1}')",
      "esxcfg-vswitch -P vmnic1 -V $portid ${var.networks.vsphere.VMotion.vds_name}",
      "portid=$(esxcfg-vswitch -l | grep -A4 ${var.networks.vsphere.VMotion.vds_name} | grep -A2 DVPort | grep vmnic3 | awk '{print $1}' )",
      "esxcfg-vswitch -Q vmnic3 -V $portid ${var.networks.vsphere.VMotion.vds_name}"
    ]
  }
}

resource "time_sleep" "wait_before_adding_vsan_vds_uplink_temporary" {
  depends_on = [null_resource.migrating_vmotion_vds_uplink]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  create_duration = "60s"
}

resource "null_resource" "adding_vsan_vds_uplink_temporary" {
  depends_on = [time_sleep.wait_before_adding_vsan_vds_uplink_temporary]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  provisioner "local-exec" {
    command = "/bin/bash 16_vCenter_adding_uplink_vsan.sh"
  }
}

resource "null_resource" "migrating_vmk_vsan" {
  depends_on = [null_resource.adding_vsan_vds_uplink_temporary]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  provisioner "local-exec" {
    command = "ansible-playbook ansible/pb-vmk-vsan.yml --extra-vars @/root/nested_vsphere.json"
  }
}

resource "null_resource" "delete_vswitch_vsan" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  depends_on = [null_resource.migrating_vmk_vsan]
  provisioner "local-exec" {
    command = "/bin/bash 17_esxi_delete_vswitch_vsan.sh"
  }
}

resource "null_resource" "migrating_vsan_vds_uplink" {
  depends_on = [null_resource.delete_vswitch_vsan]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index]
    type        = "ssh"
    agent       = false
    user        = "root"
    password    = var.nested_esxi_root_password
  }

  provisioner "remote-exec" {
    inline      = [
      "portid=$(esxcfg-vswitch -l | grep -A4 ${var.networks.vsphere.VSAN.vds_name} | grep -A2 DVPort | grep -A1 vmnic3  | grep -v vmnic3 |awk '{print $1}')",
      "esxcfg-vswitch -P vmnic2 -V $portid ${var.networks.vsphere.VSAN.vds_name}",
      "portid=$(esxcfg-vswitch -l | grep -A4 ${var.networks.vsphere.VSAN.vds_name} | grep -A2 DVPort | grep vmnic3 | awk '{print $1}' )",
      "esxcfg-vswitch -Q vmnic3 -V $portid ${var.networks.vsphere.VSAN.vds_name}"
    ]
  }
}

resource "null_resource" "shutdown_vcsa_vcsa_final" {
  depends_on = [null_resource.migrating_vsan_vds_uplink]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.esxi_ips[0]
    type        = "ssh"
    agent       = false
    user        = "root"
    password    = var.nested_esxi_root_password
  }

  provisioner "remote-exec" {
    inline      = [
      "vim-cmd vmsvc/power.shutdown 1",
      "count=1 ; while [ $(vim-cmd vmsvc/power.getstate 1 | tail -1 | awk '{print $2}') != \"off\" ] ; do echo \"Attempt $count: Waiting for VCSA to be shutdown\"; sleep 40 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to get VCSA poweredOff\" ; exit 1 ; fi ; done"
    ]
  }
}

resource "null_resource" "reconfigure_esxi_vsphere_wo_nsx" {
  depends_on = [null_resource.shutdown_vcsa_vcsa_final]
  count = var.deployment == "vsphere_wo_nsx" && var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vsphere_underlay.datacenter}
      export GOVC_URL=${var.vsphere_underlay.vcsa}
      export GOVC_CLUSTER=${var.vsphere_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.power -s -vm.uuid ${vsphere_virtual_machine.esxi_host_single_attached[count.index].uuid}
      count=1 ; while [ $(/usr/local/bin/govc vm.info -vm.uuid ${vsphere_virtual_machine.esxi_host_single_attached[count.index].uuid} | grep "Power state:" | awk '{print $3}') != "poweredOff" ] ; do echo \"Attempt $count: Waiting for ESXi host ${count.index} to be poweredOff...\"; sleep 40 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to get ESXi host ${count.index} poweredOff\" ; exit 1 ; fi ; done
      /usr/local/bin/govc device.remove -vm.uuid ${vsphere_virtual_machine.esxi_host_single_attached[count.index].uuid} "ethernet-3"
      /usr/local/bin/govc vm.power -on -vm.uuid ${vsphere_virtual_machine.esxi_host_single_attached[count.index].uuid}
    EOT
  }
}

resource "null_resource" "reconfigure_esxi_vsphere_alb_wo_nsx" {
  depends_on = [null_resource.shutdown_vcsa_vcsa_final]
  count = (var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx") && var.vsphere_underlay.networks_vsphere_dual_attached == false  ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vsphere_underlay.datacenter}
      export GOVC_URL=${var.vsphere_underlay.vcsa}
      export GOVC_CLUSTER=${var.vsphere_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.power -s -vm.uuid ${vsphere_virtual_machine.esxi_host_vsphere_alb_wo_nsx_single_attached[count.index].uuid}
      count=1 ; while [ $(/usr/local/bin/govc vm.info -vm.uuid ${vsphere_virtual_machine.esxi_host_vsphere_alb_wo_nsx_single_attached[count.index].uuid} | grep "Power state:" | awk '{print $3}') != "poweredOff" ] ; do echo \"Attempt $count: Waiting for ESXi host ${count.index} to be poweredOff...\"; sleep 40 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to get ESXi host ${count.index} poweredOff\" ; exit 1 ; fi ; done
      /usr/local/bin/govc device.remove -vm.uuid ${vsphere_virtual_machine.esxi_host_vsphere_alb_wo_nsx_single_attached[count.index].uuid} "ethernet-3"
      /usr/local/bin/govc vm.power -on -vm.uuid ${vsphere_virtual_machine.esxi_host_vsphere_alb_wo_nsx_single_attached[count.index].uuid}
    EOT
  }
}

resource "null_resource" "reconfigure_esxi_nsx" {
  depends_on = [null_resource.shutdown_vcsa_vcsa_final]
  count = (var.deployment == "vsphere_nsx" || var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_alb_telco" || var.deployment == "vsphere_nsx_alb_vcd") && var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vsphere_underlay.datacenter}
      export GOVC_URL=${var.vsphere_underlay.vcsa}
      export GOVC_CLUSTER=${var.vsphere_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.power -s -vm.uuid ${vsphere_virtual_machine.esxi_host_nsx_single_attached[count.index].uuid}
      count=1 ; while [ $(/usr/local/bin/govc vm.info -vm.uuid ${vsphere_virtual_machine.esxi_host_nsx_single_attached[count.index].uuid} | grep "Power state:" | awk '{print $3}') != "poweredOff" ] ; do echo \"Attempt $count: Waiting for ESXi host ${count.index} to be poweredOff...\"; sleep 40 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to get ESXi host ${count.index} poweredOff\" ; exit 1 ; fi ; done
      /usr/local/bin/govc device.remove -vm.uuid ${vsphere_virtual_machine.esxi_host_nsx_single_attached[count.index].uuid} "ethernet-3"
      /usr/local/bin/govc vm.power -on -vm.uuid ${vsphere_virtual_machine.esxi_host_nsx_single_attached[count.index].uuid}
    EOT
  }
}

resource "null_resource" "wait_esxi_after_esxi_reconfig" {
  depends_on = [null_resource.reconfigure_esxi_nsx, null_resource.reconfigure_esxi_vsphere_alb_wo_nsx, null_resource.reconfigure_esxi_vsphere_wo_nsx]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index]}); do echo \"Attempt $count: Waiting for ESXi host ${count.index} to be reachable...\"; sleep 40 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to connect to ESXi host\" ; exit 1 ; fi ; done"
  }
}

resource "time_sleep" "wait_before_restart_vcsa_after_esxi_reconfigure" {
  depends_on = [null_resource.wait_esxi_after_esxi_reconfig]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  create_duration = "60s"
}

resource "null_resource" "restart_vcsa_after_esxi_reconfigure" {
  depends_on = [time_sleep.wait_before_restart_vcsa_after_esxi_reconfigure]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.esxi_ips[0]
    type        = "ssh"
    agent       = false
    user        = "root"
    password    = var.nested_esxi_root_password
  }

  provisioner "remote-exec" {
    inline      = [
      "vim-cmd vmsvc/power.on 1"
    ]
  }
}

resource "null_resource" "wait_vsca_after_esxi_reconfig" {
  depends_on = [null_resource.restart_vcsa_after_esxi_reconfigure]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip}); do echo \"Attempt $count: Waiting for vCenter to be reachable...\"; sleep 10 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to connect to vCenter\" ; exit 1 ; fi ; done"
  }
}

resource "null_resource" "test_vcenter_health_after_esxi_reconfig" {
  depends_on = [null_resource.wait_vsca_after_esxi_reconfig]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0

  provisioner "local-exec" {
    command = "/bin/bash test_vcenter_health.sh"
  }
}

resource "null_resource" "vsan_config" {
  depends_on = [null_resource.test_vcenter_health_after_esxi_reconfig]
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? 1 : 0
  provisioner "local-exec" {
    command = "/bin/bash 18_vCenter_VSAN_config.sh"
  }
}