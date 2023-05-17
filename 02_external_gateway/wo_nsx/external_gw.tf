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

resource "null_resource" "add_nic_to_gw_alb_se" {
  depends_on = [vsphere_virtual_machine.external_gw_tanzu]
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vsphere_underlay.datacenter}
      export GOVC_URL=${var.vsphere_underlay.vcsa}
      export GOVC_CLUSTER=${var.vsphere_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "external-gw-${var.date_index}" -net "${var.vsphere_underlay.networks.alb.se.name}"
    EOT
  }
}

resource "null_resource" "add_nic_to_gw_alb_backend" {
  depends_on = [null_resource.add_nic_to_gw_alb_se]
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vsphere_underlay.datacenter}
      export GOVC_URL=${var.vsphere_underlay.vcsa}
      export GOVC_CLUSTER=${var.vsphere_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "external-gw-${var.date_index}" -net "${var.vsphere_underlay.networks.alb.backend.name}"
    EOT
  }
}

resource "null_resource" "add_nic_to_gw_alb_vip" {
  depends_on = [null_resource.add_nic_to_gw_alb_backend]
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vsphere_underlay.datacenter}
      export GOVC_URL=${var.vsphere_underlay.vcsa}
      export GOVC_CLUSTER=${var.vsphere_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "external-gw-${var.date_index}" -net "${var.vsphere_underlay.networks.alb.vip.name}"
    EOT
  }
}

resource "null_resource" "add_nic_to_gw_alb_tanzu" {
  depends_on = [null_resource.add_nic_to_gw_alb_vip]
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vsphere_underlay.datacenter}
      export GOVC_URL=${var.vsphere_underlay.vcsa}
      export GOVC_CLUSTER=${var.vsphere_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "external-gw-${var.date_index}" -net "${var.vsphere_underlay.networks.alb.tanzu.name}"
    EOT
  }
}

resource "null_resource" "adding_ips" {
  depends_on = [null_resource.add_nic_to_gw_alb_tanzu]
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "iface=`ip -o link show | awk -F': ' '{print $2}' | head -2 | tail -1`",
      "mac=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}' | head -2 | tail -1`",
      "iface_se=`ip -o link show | awk -F': ' '{print $2}' | head -3 | tail -1`",
      "mac_se=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}' | head -3 | tail -1`",
      "iface_backend=`ip -o link show | awk -F': ' '{print $2}' | head -4 | tail -1`",
      "mac_backend=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}' | head -4 | tail -1`",
      "iface_vip=`ip -o link show | awk -F': ' '{print $2}' | head -5 | tail -1`",
      "mac_vip=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}' | head -5 | tail -1`",
      "iface_tanzu=`ip -o link show | awk -F': ' '{print $2}' | head -6 | tail -1`",
      "mac_tanzu=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}' | head -6 | tail -1`",
      "echo \"network:\" | sudo tee /etc/netplan/50-cloud-init.yaml",
      "echo \"    ethernets:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"        $iface:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            dhcp4: false\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            addresses: [${var.vsphere_underlay.networks.vsphere.management.external_gw_ip}/${var.vsphere_underlay.networks.vsphere.management.prefix}]\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            match:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"                macaddress: $mac\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            set-name: $iface\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            gateway4: ${var.vsphere_underlay.networks.vsphere.management.gateway}\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            nameservers:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"              addresses: [${join(", ", var.external_gw.bind.forwarders)}]\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"        $iface_se:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            dhcp4: false\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            addresses: [${var.vsphere_underlay.networks.alb.se.external_gw_ip}/${var.vsphere_underlay.networks.alb.se.prefix}]\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            match:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"                macaddress: $mac_se\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            set-name: $iface_se\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"        $iface_backend:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            dhcp4: false\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            addresses: [${var.vsphere_underlay.networks.alb.backend.external_gw_ip}/${var.vsphere_underlay.networks.alb.backend.prefix}]\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            match:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"                macaddress: $mac_backend\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            set-name: $iface_backend\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"        $iface_vip:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            dhcp4: false\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            addresses: [${var.vsphere_underlay.networks.alb.vip.external_gw_ip}/${var.vsphere_underlay.networks.alb.vip.prefix}]\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            match:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"                macaddress: $mac_vip\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            set-name: $iface_vip\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"        $iface_tanzu:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            dhcp4: false\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            addresses: [${var.vsphere_underlay.networks.alb.tanzu.external_gw_ip}/${var.vsphere_underlay.networks.alb.tanzu.prefix}]\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            match:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"                macaddress: $mac_tanzu\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            set-name: $iface_tanzu\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"    version: 2\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "sudo netplan apply",
      "sudo sysctl -w net.ipv4.ip_forward=1"
    ]
  }
}



resource "null_resource" "clear_ssh_key_external_gw_locally" {
  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${var.vsphere_underlay.networks.vsphere.management.external_gw_ip}\" || true"
  }
}


