resource "vsphere_virtual_machine" "external_gw_tanzu" {
  count = var.deployment == "vsphere_alb_wo_nsx" ? 1 : 0
  name             = "external-gw-${var.date_index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = "/${var.vsphere_underlay.datacenter}/vm/${var.vsphere_underlay.folder}"

  network_interface {
    network_id = data.vsphere_network.vsphere_underlay_network_mgmt.id
    ovf_mapping = "ens192"
  }

  #  network_interface {
  #    network_id = data.vsphere_network.se[0].id
  #    ovf_mapping = "ens33"
  #  }
  #
  #  network_interface {
  #    network_id = data.vsphere_network.backend[0].id
  #    ovf_mapping = "ens34"
  #  }
  #
  #  network_interface {
  #    network_id = data.vsphere_network.vip[0].id
  #    ovf_mapping = "ens35"
  #  }
  #
  #  network_interface {
  #    network_id = data.vsphere_network.tanzu[0].id
  #    ovf_mapping = "ens36"
  #  }

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

resource "null_resource" "add_nic_to_gw_alb_se" {
  depends_on = [vsphere_virtual_machine.external_gw_tanzu]
  count = var.deployment == "vsphere_alb_wo_nsx" ? 1 : 0

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
  count = var.deployment == "vsphere_alb_wo_nsx" ? 1 : 0

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
  count = var.deployment == "vsphere_alb_wo_nsx" ? 1 : 0

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
  count = var.deployment == "vsphere_alb_wo_nsx" ? 1 : 0

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

resource "null_resource" "add_ips_to_gw_alb_tanzu" {
  depends_on = [null_resource.add_nic_to_gw_alb_tanzu]
  count = var.deployment == "vsphere_alb_wo_nsx" ? 1 : 0

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


resource "null_resource" "set_initial_state_ip_tables" {
  count = var.deployment == "vsphere_alb_wo_nsx" ? 1 : 0
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "echo \"0\" > current_state_ip_tables.txt"
  }
}


resource "null_resource" "update_ip_tables" {
  depends_on = [null_resource.add_ips_to_gw_alb_tanzu, null_resource.set_initial_state_ip_tables]
  count = var.deployment == "vsphere_alb_wo_nsx" ? length(var.external_gw.ip_table_prefixes) : 0

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "while [[ $(cat current_state_ip_tables.txt) != \"${count.index}\" ]]; do echo \"${count.index} is waiting...\";sleep 5;done"
  }


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
      "sudo iptables -t nat -A POSTROUTING -s ${var.external_gw.ip_table_prefixes[count.index]} -o $iface -j MASQUERADE"
    ]
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "echo \"${count.index+1}\" > current_state_ip_tables.txt"
  }

}

resource "null_resource" "end" {
  depends_on = [null_resource.update_ip_tables]
  count = var.deployment == "vsphere_alb_wo_nsx" ? 1 : 0

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
      "iface_backend=`ip -o link show | awk -F': ' '{print $2}' | head -4 | tail -1`",
      "iface_vip=`ip -o link show | awk -F': ' '{print $2}' | head -5 | tail -1`",
      "iface_tanzu=`ip -o link show | awk -F': ' '{print $2}' | head -6 | tail -1`",
      "sudo iptables -A FORWARD -i $iface_backend -o $iface -j ACCEPT",
      "sudo iptables -A FORWARD -i $iface_vip -o $iface -j ACCEPT",
      "sudo iptables -A FORWARD -i $iface_tanzu -o $iface -j ACCEPT",
      "sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT",
      "sudo service ntp stop",
      "sleep 5",
      "sudo service ntp start",
    ]
  }
}
