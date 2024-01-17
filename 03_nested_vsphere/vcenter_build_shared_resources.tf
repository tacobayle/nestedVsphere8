resource "null_resource" "clear_ssh_keys" {
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline      = [
      "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}\" || true",
    ]
  }
}


resource "null_resource" "vcenter_install" {
  depends_on = [null_resource.esxi_customization_disk]

  provisioner "local-exec" {
    command = "/bin/bash 11_vCenter_iso_extract.sh"
  }
}

resource "null_resource" "wait_vsca" {
  depends_on = [null_resource.vcenter_install]

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip}); do echo \"Attempt $count: Waiting for vCenter to be reachable...\"; sleep 10 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to connect to vCenter\" ; exit 1 ; fi ; done"
  }
}

// see vcenter_config_dual_atached.tf or vcenter_config_single_attached.tf

data "template_file" "expect_script" {
  count = length(var.vsphere_nested.cluster_list)
  template = file("${path.module}/templates/expect_script.sh.template")
  vars = {
    vcenter_username        = "administrator"
    vcenter_sso_domain = var.vsphere_nested.sso.domain_name
    vsphere_nested_password = var.vsphere_nested_password
    vcenter_fqdn = "${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
    vcenter_dc = var.vsphere_nested.datacenter
    vcenter_cluster = var.vsphere_nested.cluster_list[count.index]
  }
}

resource "null_resource" "execute_expect_script" {
  count = length(var.vsphere_nested.cluster_list)
  depends_on = [null_resource.dual_uplink_update_multiple_vds, null_resource.vsan_config]
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    content = data.template_file.expect_script[count.index].rendered
    destination = "/tmp/vcenter_expect_cluster${count.index + 1}.sh"
  }

  provisioner "remote-exec" {
    inline      = [
      "chmod u+x /tmp/vcenter_expect_cluster${count.index + 1}.sh",
      "/tmp/vcenter_expect_cluster${count.index + 1}.sh"
    ]
  }
}

data "template_file" "expect_script_ip_routes" {
  template = file("${path.module}/templates/expect_ip_routes.sh.template")
  vars = {
    vsphere_nested_password = var.vsphere_nested_password
    vcenter_fqdn = "${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
  }
}


resource "null_resource" "set_initial_vcenter_iproute" {
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" || var.deployment == "vsphere_nsx_tanzu_alb" ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "echo \"0\" > current_state_vcenter_iproute.txt"
  }
}

resource "null_resource" "vcenter_iproute_0" {
  depends_on = [null_resource.set_initial_vcenter_iproute, null_resource.execute_expect_script]
  count      = var.deployment == "vsphere_tanzu_alb_wo_nsx" || var.deployment == "vsphere_nsx_tanzu_alb" ? 1 : 0

  provisioner "local-exec" {
    command = "cat > expect_script_ip_routes.sh <<'EOF'\n${data.template_file.expect_script_ip_routes.rendered}\nEOF"
  }
}

resource "null_resource" "vcenter_iproute_1" {
  depends_on = [null_resource.vcenter_iproute_0]
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" || var.deployment == "vsphere_nsx_tanzu_alb" ? length(var.vsphere_nested.ip_routes_vcenter) : 0

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "while [[ $(cat current_state_vcenter_iproute.txt) != \"${count.index}\" ]]; do echo \"${count.index} is waiting...\";sleep 5;done"
  }

  provisioner "local-exec" {
    command = "echo 'send \"ip route add ${var.vsphere_nested.ip_routes_vcenter[count.index]} via ${var.vsphere_underlay.networks.vsphere.management.external_gw_ip}\r\"' | tee -a expect_script_ip_routes.sh ; echo 'expect \" ]# \"' | tee -a expect_script_ip_routes.sh"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "echo \"${count.index+1}\" > current_state_vcenter_iproute.txt"
  }
}

resource "null_resource" "vcenter_iproute_2" {
  depends_on = [null_resource.vcenter_iproute_1]
  count      = var.deployment == "vsphere_tanzu_alb_wo_nsx" || var.deployment == "vsphere_nsx_tanzu_alb" ? 1 : 0

  provisioner "local-exec" {
    command = "cat templates/expect_end_iproutes.sh | tee -a expect_script_ip_routes.sh"
  }
}

resource "null_resource" "execute_expect_script_vcenter_ip_routes" {
  depends_on = [null_resource.vcenter_iproute_2]
  count      = var.deployment == "vsphere_tanzu_alb_wo_nsx" || var.deployment == "vsphere_nsx_tanzu_alb" ? 1 : 0

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    source = "expect_script_ip_routes.sh"
    destination = "/tmp/vcenter_expect_ip_routes.sh"
  }

  provisioner "remote-exec" {
    inline      = [
      "chmod u+x /tmp/vcenter_expect_ip_routes.sh",
      "/tmp/vcenter_expect_ip_routes.sh"
    ]
  }
}

resource "null_resource" "execute_expect_script_esxi_ip_routes" {
  depends_on = [null_resource.execute_expect_script]
  count      = var.deployment == "vsphere_tanzu_alb_wo_nsx" || var.deployment == "vsphere_nsx_tanzu_alb" ? 1 : 0

  provisioner "local-exec" {
    command = "/bin/bash 19_esxi_ip_routes.sh"
  }
}

resource "null_resource" "retrieve_vcenter_finger_print" {
  depends_on = [null_resource.execute_expect_script]
  provisioner "local-exec" {
    command = "rm -f /root/vcenter_finger_print.txt ; echo | openssl s_client -connect ${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}:443 | openssl x509 -fingerprint -noout |  cut -d\"=\" -f2 | tee /root/vcenter_finger_print.txt > /dev/null "
  }
}