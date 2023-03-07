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

resource "null_resource" "add_nic_to_gw_network_nsx_external" {
  depends_on = [vsphere_virtual_machine.external_gw]

  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vcenter_underlay.dc}
      export GOVC_URL=${var.vcenter_underlay.server}
      export GOVC_CLUSTER=${var.vcenter_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "external-gw-${var.date_index}" -net "${var.vcenter_underlay.networks.nsx.external.name}"
    EOT
  }
}

resource "null_resource" "add_nic_to_gw_network_nsx_overlay" {
  depends_on = [vsphere_virtual_machine.external_gw, null_resource.add_nic_to_gw_network_nsx_external]

  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vcenter_underlay.dc}
      export GOVC_URL=${var.vcenter_underlay.server}
      export GOVC_CLUSTER=${var.vcenter_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "external-gw-${var.date_index}" -net "${var.vcenter_underlay.networks.nsx.overlay.name}"
    EOT
  }
}

resource "null_resource" "add_nic_to_gw_network_nsx_overlay_edge" {
  depends_on = [vsphere_virtual_machine.external_gw, null_resource.add_nic_to_gw_network_nsx_external, null_resource.add_nic_to_gw_network_nsx_overlay]

  provisioner "local-exec" {
    command = <<-EOT
      export GOVC_USERNAME=${var.vsphere_underlay_username}
      export GOVC_PASSWORD=${var.vsphere_underlay_password}
      export GOVC_DATACENTER=${var.vcenter_underlay.dc}
      export GOVC_URL=${var.vcenter_underlay.server}
      export GOVC_CLUSTER=${var.vcenter_underlay.cluster}
      export GOVC_INSECURE=true
      /usr/local/bin/govc vm.network.add -vm "external-gw-${var.date_index}" -net "${var.vcenter_underlay.networks.nsx.overlay_edge.name}"
    EOT
  }
}

resource "null_resource" "adding_ip_to_nsx_external" {
  depends_on = [null_resource.add_nic_to_gw_network_nsx_external, null_resource.add_nic_to_gw_network_nsx_overlay, null_resource.add_nic_to_gw_network_nsx_overlay_edge]
  count = 1

  connection {
    host        = var.vcenter_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "iface=`ip -o link show | awk -F': ' '{print $2}' | head -2 | tail -1`",
      "mac=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}' | head -2 | tail -1`",
      "ifaceSecond=`ip -o link show | awk -F': ' '{print $2}' | head -3 | tail -1`",
      "macSecond=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}' | head -3 | tail -1`",
      "sudo ip link set dev $ifaceThird mtu ${var.networks.nsx.nsx_overlay.max_mtu}",
      "sudo ip link set dev $ifaceLastName mtu ${var.networks.nsx.nsx_overlay_edge.max_mtu}",
      "echo \"network:\" | sudo tee /etc/netplan/50-cloud-init.yaml",
      "echo \"    ethernets:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"        $iface:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            dhcp4: false\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            addresses: [${var.vcenter_underlay.networks.vsphere.management.external_gw_ip}/${var.vcenter_underlay.networks.vsphere.management.prefix}]\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            match:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"                macaddress: $mac\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            set-name: $iface\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            gateway4: ${var.vcenter_underlay.networks.vsphere.management.gateway}\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            nameservers:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"              addresses: [${join(", ", var.external_gw.bind.forwarders)}]\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"        $ifaceSecond:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            dhcp4: false\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            addresses: [${var.vcenter_underlay.networks.nsx.external.external_gw_ip}/${var.vcenter_underlay.networks.nsx.external.prefix}]\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            routes:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
    ]
  }
}

resource "null_resource" "set_initial_state" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "echo \"0\" > current_state.txt"
  }
}




resource "null_resource" "update_ip_routes" {
  depends_on = [null_resource.adding_ip_to_nsx_external, null_resource.set_initial_state]
  count = length(var.external_gw.routes)

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "while [[ $(cat current_state.txt) != \"${count.index}\" ]]; do echo \"${count.index} is waiting...\";sleep 5;done"
  }


  connection {
    host        = var.vcenter_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"            - to: ${var.external_gw.routes[count.index].to}\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"              via: ${var.external_gw.routes[count.index].via}\" | sudo tee -a /etc/netplan/50-cloud-init.yaml"
    ]
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "echo \"${count.index+1}\" > current_state.txt"
  }

}



resource "null_resource" "adding_ip_to_nsx_overlay_and_nsx_overlay_edge" {
  depends_on = [null_resource.update_ip_routes]
  count = 1

  connection {
    host        = var.vcenter_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "iface=`ip -o link show | awk -F': ' '{print $2}' | head -2 | tail -1`",
      "ifaceSecond=`ip -o link show | awk -F': ' '{print $2}' | head -3 | tail -1`",
      "macSecond=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}' | head -3 | tail -1`",
      "ifaceThird=`ip -o link show | awk -F': ' '{print $2}' | head -4 | tail -1`",
      "macThird=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}' | head -4 | tail -1`",
      "ifaceLastName=`ip -o link show | awk -F': ' '{print $2}' | tail -1`",
      "macLast=`ip -o link show | awk -F'link/ether ' '{print $2}' | awk -F' ' '{print $1}'| tail -1`",
      "echo \"            match:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"                macaddress: $macSecond\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            set-name: $ifaceSecond\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"        $ifaceThird:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            dhcp4: false\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            addresses: [${var.vcenter_underlay.networks.nsx.overlay.nsx_pool.gateway}/${var.vcenter_underlay.networks.nsx.overlay.prefix}]\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            match:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"                macaddress: $macThird\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            set-name: $ifaceThird\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            mtu: ${var.networks.nsx.nsx_overlay.max_mtu}\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"        $ifaceLastName:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            dhcp4: false\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            addresses: [${var.vcenter_underlay.networks.nsx.overlay_edge.nsx_pool.gateway}/${var.vcenter_underlay.networks.nsx.overlay_edge.prefix}]\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            match:\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"                macaddress: $macLast\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            set-name: $ifaceLastName\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"            mtu: ${var.networks.nsx.nsx_overlay_edge.max_mtu}\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "echo \"    version: 2\" | sudo tee -a /etc/netplan/50-cloud-init.yaml",
      "sudo netplan apply",
      "sudo sysctl -w net.ipv4.ip_forward=1",
      "echo \"net.ipv4.ip_forward=1\" | sudo tee -a /etc/sysctl.conf",
      "sudo iptables -t nat -A POSTROUTING -o $iface -j MASQUERADE",
      "sudo iptables -A FORWARD -i $ifaceSecond -o $iface -j ACCEPT",
      "sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT",
      "sudo service ntp stop",
      "sleep 5",
      "sudo service ntp start",
    ]
  }
}