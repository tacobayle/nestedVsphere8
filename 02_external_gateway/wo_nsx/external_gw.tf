resource "vsphere_content_library" "library_external_gw" {
  count = 1
  name            = "cl_tf_external_gw-${var.date_index}"
  storage_backing = [data.vsphere_datastore.datastore.id]
}

resource "vsphere_content_library_item" "file_external_gw" {
  count = 1
  name        = basename(var.ubuntu_ova_path)
  library_id  = vsphere_content_library.library_external_gw[0].id
  file_url = var.ubuntu_ova_path
}

data "template_file" "external_gw_userdata" {
  count = var.deployment == "vsphere_wo_nsx" ? 1 : 0
  template = file("${path.module}/userdata/external_gw.userdata")
  vars = {
    pubkey        = file("/root/.ssh/id_rsa.pub")
    username = "ubuntu"
    ipCidr  = "${var.vsphere_underlay.networks.vsphere.management.external_gw_ip}/${var.vsphere_underlay.networks.vsphere.management.prefix}"
    ip = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    defaultGw = var.vsphere_underlay.networks.vsphere.management.gateway
    password      = var.ubuntu_password
    hostname = "external-gw-${var.date_index}"
    ip_vcenter = var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip
    vcenter_name = var.vsphere_nested.vcsa_name
    dns_domain = var.external_gw.bind.domain
//    ip_data_cidr  = "${var.vsphere_underlay.networks.vsphere.management.external_gw_ip}/${var.vsphere_underlay.networks.vsphere.management.prefix}"
    dns      = join(", ", var.external_gw.bind.forwarders)
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    privateKey = "/root/.ssh/id_rsa"
    ansible_version = var.ansible_version
    avi_sdk_version = var.avi_sdk_version
    forwarders = join("; ", var.external_gw.bind.forwarders)
    domain = var.external_gw.bind.domain
    reverse = var.external_gw.bind.reverse
    keyName = "myKeyName"
    secret = base64encode(var.bind_password)
    ntp = var.external_gw.ntp
    lastOctet = split(".", var.vsphere_underlay.networks.vsphere.management.external_gw_ip)[3]
    vcsa_nested_ip = var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip
    vcenter_name = var.vsphere_nested.vcsa_name
    vcd_ip = var.vcd_ip
    nfs_path = var.external_gw.nfs_path
  }
}

resource "vsphere_virtual_machine" "external_gw" {
  count = var.deployment == "vsphere_wo_nsx" ? 1 : 0
  name             = "external-gw-${var.date_index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = "/${var.vsphere_underlay.datacenter}/vm/${var.vsphere_underlay.folder}"

  network_interface {
    network_id = data.vsphere_network.vsphere_underlay_network_mgmt.id
  }

//  network_interface {
//    network_id = data.vsphere_network.vsphere_underlay_network_external.id
//  }

  num_cpus = var.cpu
  memory = var.memory
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.disk
    label            = "external-gw-${var.date_index}.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.file_external_gw[0].id
  }

  vapp {
    properties = {
      hostname    = "external-gw-${var.date_index}"
      public-keys = file("/root/.ssh/id_rsa.pub")
      user-data   = base64encode(data.template_file.external_gw_userdata[0].rendered)
    }
  }

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}

data "template_file" "external_gw_userdata_tanzu" {
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0
  template = file("${path.module}/userdata/external_gw_tanzu_wo_nsx.userdata")
  vars = {
    pubkey        = file("/root/.ssh/id_rsa.pub")
    username = "ubuntu"
    ipCidr  = "${var.vsphere_underlay.networks.vsphere.management.external_gw_ip}/${var.vsphere_underlay.networks.vsphere.management.prefix}"
    ipCidr_se = "${var.vsphere_underlay.networks.alb.se.external_gw_ip}/${var.vsphere_underlay.networks.alb.se.prefix}"
    ipCidr_backend = "${var.vsphere_underlay.networks.alb.backend.external_gw_ip}/${var.vsphere_underlay.networks.alb.backend.prefix}"
    ipCidr_vip = "${var.vsphere_underlay.networks.alb.vip.external_gw_ip}/${var.vsphere_underlay.networks.alb.vip.prefix}"
    ipCidr_tanzu = "${var.vsphere_underlay.networks.alb.tanzu.external_gw_ip}/${var.vsphere_underlay.networks.alb.tanzu.prefix}"
    ip = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    defaultGw = var.vsphere_underlay.networks.vsphere.management.gateway
    password      = var.ubuntu_password
    hostname = "external-gw-${var.date_index}"
    ip_vcenter = var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip
    vcenter_name = var.vsphere_nested.vcsa_name
    dns_domain = var.external_gw.bind.domain
    //    ip_data_cidr  = "${var.vsphere_underlay.networks.vsphere.management.external_gw_ip}/${var.vsphere_underlay.networks.vsphere.management.prefix}"
    dns      = join(", ", var.external_gw.bind.forwarders)
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    privateKey = "/root/.ssh/id_rsa"
    ansible_version = var.ansible_version
    avi_sdk_version = var.avi_sdk_version
    forwarders = join("; ", var.external_gw.bind.forwarders)
    domain = var.external_gw.bind.domain
    reverse = var.external_gw.bind.reverse
    keyName = "myKeyName"
    secret = base64encode(var.bind_password)
    ntp = var.external_gw.ntp
    lastOctet = split(".", var.vsphere_underlay.networks.vsphere.management.external_gw_ip)[3]
    vcsa_nested_ip = var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip
    vcenter_name = var.vsphere_nested.vcsa_name
    vcd_ip = var.vcd_ip
    nfs_path = var.external_gw.nfs_path
  }
}


resource "vsphere_virtual_machine" "external_gw_tanzu" {
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0
  name             = "external-gw-${var.date_index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = "/${var.vsphere_underlay.datacenter}/vm/${var.vsphere_underlay.folder}"

  network_interface {
    network_id = data.vsphere_network.vsphere_underlay_network_mgmt.id
    ovf_mapping = "ens192"
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

  //  network_interface {
  //    network_id = data.vsphere_network.vsphere_underlay_network_external.id
  //  }

  num_cpus = var.cpu
  memory = var.memory
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.disk
    label            = "external-gw-${var.date_index}.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.file_external_gw[0].id
  }

  vapp {
    properties = {
      hostname    = "external-gw-${var.date_index}"
      public-keys = file("/root/.ssh/id_rsa.pub")
      user-data   = base64encode(data.template_file.external_gw_userdata_tanzu[0].rendered)
    }
  }

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}

resource "null_resource" "clear_ssh_key_external_gw_locally" {
  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${var.vsphere_underlay.networks.vsphere.management.external_gw_ip}\" || true"
  }
}


