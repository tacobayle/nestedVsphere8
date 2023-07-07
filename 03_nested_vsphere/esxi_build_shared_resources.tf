resource "local_file" "ks_cust_multiple_vswitch" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == true ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  content     = templatefile("${path.module}/templates/ks_cust_multiple_vswitch.cfg.tmpl",
    { nested_esxi_root_password = var.nested_esxi_root_password,
      keyboard_type = var.keyboard_type,
      ip_mgmt = var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index],
      netmask = var.vsphere_underlay.networks.vsphere.management.netmask,
      gateway = var.vsphere_underlay.networks.vsphere.management.gateway,
      ip_vmotion = var.vsphere_underlay.networks.vsphere.vmotion.esxi_ips[count.index],
      netmask_vmotion = var.vsphere_underlay.networks.vsphere.vmotion.netmask,
      ip_vsan = var.vsphere_underlay.networks.vsphere.vsan.esxi_ips[count.index],
      netmask_vsan = var.vsphere_underlay.networks.vsphere.vsan.netmask,
      ntp = var.vsphere_underlay.networks.vsphere.management.external_gw_ip,
      nameserver = var.vsphere_underlay.networks.vsphere.management.external_gw_ip,
      hostname = "${var.vsphere_nested.esxi.basename}${count.index + 1}.${var.external_gw.bind.domain}"
    }
  )
  filename = "/root/ks_cust.cfg.${count.index}"
}

resource "local_file" "ks_cust_single_attached" {
  count = var.vsphere_underlay.networks_vsphere_dual_attached == false ? length(var.vsphere_underlay.networks.vsphere.management.esxi_ips) : 0
  content     = templatefile("${path.module}/templates/ks_cust_multiple_vswitch_single_attached.cfg.tmpl",
    { nested_esxi_root_password = var.nested_esxi_root_password,
      keyboard_type = var.keyboard_type,
      ip_mgmt = var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index],
      netmask = var.vsphere_underlay.networks.vsphere.management.netmask,
      gateway = var.vsphere_underlay.networks.vsphere.management.gateway,
      ip_vmotion = var.vsphere_underlay.networks.vsphere.vmotion.esxi_ips[count.index],
      netmask_vmotion = var.vsphere_underlay.networks.vsphere.vmotion.netmask,
      ip_vsan = var.vsphere_underlay.networks.vsphere.vsan.esxi_ips[count.index],
      netmask_vsan = var.vsphere_underlay.networks.vsphere.vsan.netmask,
      ntp = var.vsphere_underlay.networks.vsphere.management.external_gw_ip,
      nameserver = var.vsphere_underlay.networks.vsphere.management.external_gw_ip,
      hostname = "${var.vsphere_nested.esxi.basename}${count.index + 1}.${var.external_gw.bind.domain}"
    }
  )
  filename = "/root/ks_cust.cfg.${count.index}"
}

resource "null_resource" "iso_build" {
  depends_on = [local_file.ks_cust_multiple_vswitch, local_file.ks_cust_single_attached]
  provisioner "local-exec" {
    command = "/bin/bash 01_esxi_iso_build.sh"
  }
}

resource "vsphere_file" "iso_upload" {
  depends_on = [null_resource.iso_build]
  count = length(var.vsphere_underlay.networks.vsphere.management.esxi_ips)
  datacenter       = var.vsphere_underlay.datacenter
  datastore        = var.vsphere_underlay.datastore
  source_file      = "${var.iso_location}${count.index}.iso"
  destination_file = "isos/${basename(var.iso_location)}-${var.date_index}-${count.index}.iso"
}

resource "null_resource" "iso_destroy" {
  depends_on = [vsphere_file.iso_upload]
  provisioner "local-exec" {
    command = "/bin/bash 02_esxi_iso_remove.sh"
  }
}

resource "null_resource" "wait_esxi" {
  depends_on = [vsphere_virtual_machine.esxi_host, vsphere_virtual_machine.esxi_host_nsx, vsphere_virtual_machine.esxi_host_tanzu]
  count = length(var.vsphere_underlay.networks.vsphere.management.esxi_ips)

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index]}); do echo \"Attempt $count: Waiting for ESXi host ${count.index} to be reachable...\"; sleep 40 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to connect to ESXi host\" ; exit 1 ; fi ; done"
  }
}

resource "null_resource" "esxi_customization_disk" {
  depends_on = [null_resource.wait_esxi]

  provisioner "local-exec" {
    command = "/bin/bash 03_esxi_customization_disk.sh"
  }
}

resource "null_resource" "vsphere_underlay_clean_up" {
  depends_on = [null_resource.esxi_customization_disk]

  provisioner "local-exec" {
    command = "/bin/bash 04_vcenter_underlay_clean_up.sh"
  }
}

resource "null_resource" "clear_ssh_key_esxi_locally" {
  count = length(var.vsphere_underlay.networks.vsphere.management.esxi_ips)
  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${var.vsphere_underlay.networks.vsphere.management.esxi_ips[count.index]}\" || true"
  }
}