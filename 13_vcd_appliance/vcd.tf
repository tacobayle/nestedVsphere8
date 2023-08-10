resource "vsphere_virtual_machine" "vcd_medium" {
  name             = var.vcd_appliance.name
  datastore_id     = data.vsphere_datastore.datastore_nested.id
  resource_pool_id = data.vsphere_resource_pool.resource_pool_nested.id
  folder           = vsphere_folder.vcd.path
  wait_for_guest_net_timeout = 10

  network_interface {
    network_id = data.vsphere_network.vcenter_network_mgmt.id
    ovf_mapping = "eth0"
  }

  network_interface {
    network_id = data.vsphere_network.vcenter_network_db.id
    ovf_mapping = "eth1"
  }

  num_cpus = var.vcd_appliance.cpu
  memory = var.vcd_appliance.memory
  scsi_type = "lsilogic"

  disk {
    size             = var.vcd_appliance.disk1
    label            = "vcd1.lab_vmdk"
    thin_provisioned = true
    unit_number = 0
  }

  disk {
    size             = var.vcd_appliance.disk2
    label            = "vcd2.lab_vmdk"
    thin_provisioned = true
    unit_number = 1
  }

  disk {
    size             = var.vcd_appliance.disk3
    label            = "vcd3.lab_vmdk"
    thin_provisioned = true
    unit_number = 2
  }


  clone {
    template_uuid = vsphere_content_library_item.nested_library_vcd_item.id
  }

  vapp {
    properties = {
      varoot-password = var.vcd_root_password
      DNS = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
      domain = var.vcd_appliance.name
      gateway = var.vsphere_underlay.networks.vsphere.management.vcd_nested_ip
      ip0 = var.vsphere_underlay.networks.vsphere.management.vcd_nested_ip
      ip1 = var.vsphere_underlay.networks.vsphere.vsan.vcd_nested_ip
      netmask0 = var.vsphere_underlay.networks.vsphere.management.prefix
      netmask1 = var.vsphere_underlay.networks.vsphere.vsan.prefix
      searchpath = var.external_gw.bind.domain
      enable_ssh = "True"
      expire_root_password = "False"
      ntp-server = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    }
  }
}

resource "null_resource" "wait_https_vcd_appliance" {
  depends_on = [vsphere_virtual_machine.vcd_medium]

  provisioner "local-exec" {
    command = "until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.vcd_nested_ip}:5480); do echo 'Waiting for VCD Appliance API to be ready'; sleep 60 ; done"
  }
}

resource "null_resource" "configure_appliance" {
  depends_on = [null_resource.wait_https_vcd_appliance]

  provisioner "local-exec" {
    command = "/bin/bash /nestedVsphere8/bash/vcd/vcd_configure_appliance.sh"
  }
}