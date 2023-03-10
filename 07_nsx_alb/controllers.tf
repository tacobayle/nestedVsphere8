resource "vsphere_folder" "avi" {
  path          = "avi-controllers"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

resource "vsphere_content_library" "nested_library_avi" {
  name            = "avi_controller"
  storage_backing = [data.vsphere_datastore.datastore_nested.id]
  description     = "avi_controller"
}

resource "vsphere_content_library_item" "nested_library_avi_item" {
  count = 1
  name        = "avi.ova"
  description = "avi.ova"
  library_id  = vsphere_content_library.nested_library_avi.id
  file_url = "/home/ubuntu/${basename(var.avi_ova_path)}"
}


resource "vsphere_virtual_machine" "controller" {
  count = 1
  name             = "avi-controller-${count.index + 1}"
  datastore_id     = data.vsphere_datastore.datastore_nested.id
  resource_pool_id = data.vsphere_resource_pool.resource_pool_nested.id
  folder           = vsphere_folder.avi.path

  network_interface {
    network_id = data.vsphere_network.vcenter_network_mgmt_nested.id
  }

  num_cpus = var.avi.cpu
  memory = var.avi.memory
  wait_for_guest_net_timeout = 4
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.avi.disk
    label            = "avi-controller-${count.index + 1}.lab_vmdk"
    thin_provisioned = true
  }

  clone {
    template_uuid = vsphere_content_library_item.nested_library_avi_item.id
  }

  vapp {
    properties = {
      "mgmt-ip"     = var.vsphere_underlay.networks.vsphere.management.avi_nested_ip
      "mgmt-mask"   = var.vsphere_underlay.networks.vsphere.management.netmask
      "default-gw"  = var.vsphere_underlay.networks.vsphere.management.gateway
    }
  }
}

resource "null_resource" "wait_https_controller" {
  depends_on = [vsphere_virtual_machine.controller]
  count = 1

  provisioner "local-exec" {
    command = "until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip}); do echo 'Waiting for Avi Controllers to be ready'; sleep 60 ; done"
  }
}

