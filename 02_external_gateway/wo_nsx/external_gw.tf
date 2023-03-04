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
  count = 1
  template = file("${path.module}/userdata/external_gw.userdata")
  vars = {
    pubkey        = file("/root/.ssh/id_rsa.pub")
    username = "ubuntu"
    ipCidr  = "${var.vcenter_underlay.networks.vsphere.management.external_gw_ip}/${var.vcenter_underlay.networks.vsphere.management.prefix}"
    ip = var.vcenter_underlay.networks.vsphere.management.external_gw_ip
    defaultGw = var.vcenter_underlay.networks.vsphere.management.gateway
    password      = var.ubuntu_password
    hostname = "external-gw-${var.date_index}"
    ansible_version = var.ansible_version
    avi_sdk_version = var.avi_sdk_version
    ip_vcenter = var.vcenter_underlay.networks.vsphere.management.vcenter_ip
    vcenter_name = var.vcenter.name
    dns_domain = var.external_gw.bind.domain
//    ip_data_cidr  = "${var.vcenter_underlay.networks.vsphere.management.external_gw_ip}/${var.vcenter_underlay.networks.vsphere.management.prefix}"
    dns      = join(", ", var.external_gw.bind.forwarders)
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    privateKey = "/root/.ssh/id_rsa"
    forwarders = join("; ", var.external_gw.bind.forwarders)
    domain = var.external_gw.bind.domain
    reverse = var.external_gw.bind.reverse
    keyName = "myKeyName"
    secret = base64encode(var.bind_password)
    ntp = var.external_gw.ntp
    lastOctet = split(".", var.vcenter_underlay.networks.vsphere.management.external_gw_ip)[3]
    vcenter_ip = var.vcenter_underlay.networks.vsphere.management.vcenter_ip
    vcenter_name = var.vcenter.name
  }
}

resource "vsphere_virtual_machine" "external_gw" {
  count = 1
  name             = "external-gw-${var.date_index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = "/${var.vcenter_underlay.dc}/vm/${var.vcenter_underlay.folder}"

  network_interface {
    network_id = data.vsphere_network.vcenter_underlay_network_mgmt.id
  }

//  network_interface {
//    network_id = data.vsphere_network.vcenter_underlay_network_external.id
//  }

  num_cpus = var.external_gw.cpu
  memory = var.external_gw.memory
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.external_gw.disk
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
    host        = var.vcenter_underlay.networks.vsphere.management.external_gw_ip
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
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${var.vcenter_underlay.networks.vsphere.management.external_gw_ip}\" || true"
  }
}


