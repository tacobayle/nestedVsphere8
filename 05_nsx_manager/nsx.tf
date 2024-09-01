data "vsphere_folder" "nsx" {
  path          = "/${var.vsphere_underlay.datacenter}/vm/${var.vsphere_underlay.folder}"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_content_library" "nsx" {
  name            = "cl_nsx-${var.date_index}"
  storage_backing = [data.vsphere_datastore.datastore.id]
}

resource "vsphere_content_library_item" "nsx" {
  name        = basename(var.nsx_ova_path)
  library_id  = vsphere_content_library.nsx.id
  file_url = var.nsx_ova_path
}

resource "vsphere_virtual_machine" "nsx_medium" {
  name             = "${var.external_gw.nsx_manager_name}-${var.date_index}"
  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  folder           = data.vsphere_folder.nsx.path
  wait_for_guest_net_timeout = 10

  network_interface {
    network_id = data.vsphere_network.vsphere_underlay_network_mgmt.id
  }

  num_cpus = 6
  memory = 24576

  disk {
    size             = 200
    label            = "${var.external_gw.nsx_manager_name}-${var.date_index}.lab_vmdk"
    thin_provisioned = true
  }

  clone {
    template_uuid = vsphere_content_library_item.nsx.id
  }

  vapp {
    properties = {
      nsx_allowSSHRootLogin = "True"
      nsx_cli_audit_passwd_0 = var.nsx_password
      nsx_cli_passwd_0 = var.nsx_password
      nsx_dns1_0 = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
      nsx_gateway_0 = var.vsphere_underlay.networks.vsphere.management.gateway
      nsx_hostname = "${var.external_gw.nsx_manager_name}.${var.external_gw.bind.domain}"
      nsx_ip_0 = var.vsphere_underlay.networks.vsphere.management.nsx_nested_ip
      nsx_isSSHEnabled = "True"
      nsx_netmask_0 = var.vsphere_underlay.networks.vsphere.management.netmask
      nsx_ntp_0 = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
      nsx_passwd_0 = var.nsx_password
      nsx_role = "NSX Manager"
      nsx_swIntegrityCheck = "False"
    }
  }
}

resource "null_resource" "wait_nsx" {
  depends_on = [vsphere_virtual_machine.nsx_medium]

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.nsx_nested_ip}); do echo \"Attempt $count: Waiting for NSX Manager to be reachable...\"; sleep 30 ; count=$((count+1)) ;  if [ \"$count\" = 60 ]; then echo \"ERROR: Unable to connect to NSX Manager\" ; exit 1 ; fi ; done"
  }
}