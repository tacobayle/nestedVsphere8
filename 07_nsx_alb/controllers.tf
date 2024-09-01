data "vsphere_folder" "avi" {
  path          = "/${var.vsphere_underlay.datacenter}/vm/${var.vsphere_underlay.folder}"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_content_library" "avi" {
  name            = "cl_avi-${var.date_index}"
  storage_backing = [data.vsphere_datastore.datastore.id]
}

resource "vsphere_content_library_item" "avi" {
  name        = basename(var.avi_ova_path)
  library_id  = vsphere_content_library.avi.id
  file_url = "/root/${basename(var.avi_ova_path)}"
}


resource "vsphere_virtual_machine" "controller" {
  count            = 1
  name             = "${var.external_gw.alb_controller_name}-${var.date_index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = data.vsphere_folder.avi.path

  network_interface {
    network_id = data.vsphere_network.vsphere_underlay_network_mgmt.id
  }

  num_cpus = var.avi.cpu
  memory = var.avi.memory
  wait_for_guest_net_timeout = 4
  guest_id = "ubuntu64Guest"

  disk {
    size             = var.avi.disk
    label            = "${var.external_gw.alb_controller_name}-${var.date_index}.lab_vmdk"
    thin_provisioned = true
  }

  clone {
    template_uuid = vsphere_content_library_item.avi.id
  }

  vapp {
    properties = {
      "mgmt-ip"     = var.vsphere_underlay.networks.vsphere.management.avi_nested_ip
      "mgmt-mask"   = var.vsphere_underlay.networks.vsphere.management.netmask
      "default-gw"  = var.vsphere_underlay.networks.vsphere.management.gateway
    }
  }
}

