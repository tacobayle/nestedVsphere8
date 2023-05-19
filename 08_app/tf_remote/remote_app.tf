resource "vsphere_folder" "apps" {
  path          = var.app.folder
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

resource "vsphere_content_library" "nested_library_avi_app" {
  name            = "avi_app"
  storage_backing = [data.vsphere_datastore.datastore_nested.id]
}

resource "vsphere_content_library_item" "nested_library_item_avi_app" {
  name        = "ubuntu.ova"
  library_id  = vsphere_content_library.nested_library_avi_app.id
  file_url = "/home/ubuntu/${basename(var.ubuntu_ova_path)}"
}

data "template_file" "avi_app_userdata" {
  count = length(var.app_ips)
  template = file("${path.module}/userdata/avi_app.userdata")
  vars = {
    username     = var.app.username
    hostname     = "${var.app.basename}${count.index + 1}"
    password      = var.ubuntu_password
    pubkey       = file("/home/ubuntu/.ssh/id_rsa.pub")
    netplan_file  = var.app.netplan_file
    prefix = split("/", var.app_cidr[count.index])[1]
    ip = var.app_ips[count.index]
    mtu = var.app.mtu
    default_gw = cidrhost(var.app_cidr[count.index], "1")
    dns = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
    avi_app_docker_image = var.app.avi_app_docker_image
    avi_app_tcp_port = var.app.avi_app_tcp_port
    hackazon_docker_image = var.app.hackazon_docker_image
    hackazon_tcp_port = var.app.hackazon_tcp_port
  }
}

resource "vsphere_virtual_machine" "avi_app" {
  count = length(var.app_ips)
  name             = "${var.app.basename}${count.index + 1}"
  datastore_id     = data.vsphere_datastore.datastore_nested.id
  resource_pool_id = data.vsphere_resource_pool.resource_pool_nested.id
  folder           = vsphere_folder.apps.path

  network_interface {
    network_id = data.vsphere_network.app[count.index].id
  }

  num_cpus = var.app.cpu
  memory = var.app.memory
  guest_id = "ubuntu64Guest"
  wait_for_guest_net_timeout = 10

  disk {
    size             = var.app.disk
    label            = "${var.app.basename}${count.index + 1}.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.nested_library_item_avi_app.id
  }

  vapp {
    properties = {
      hostname    = "${var.app.basename}${count.index + 1}"
      public-keys = file("/home/ubuntu/.ssh/id_rsa.pub")
      user-data   = base64encode(data.template_file.avi_app_userdata[count.index].rendered)
    }
  }

  connection {
    host        = var.app_ips[count.index]
    type        = "ssh"
    agent       = false
    user        = var.app.username
    private_key = file("/home/ubuntu/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}