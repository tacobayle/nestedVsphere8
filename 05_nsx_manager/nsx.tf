resource "vsphere_folder" "nsx" {
  path          = "nsx"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

resource "vsphere_virtual_machine" "nsx_medium" {
  name             = "nsx-manager"
  datastore_id     = data.vsphere_datastore.datastore_nested.id
  resource_pool_id = data.vsphere_resource_pool.resource_pool_nested.id
  folder           = vsphere_folder.nsx.path
  wait_for_guest_net_timeout = 10

  network_interface {
    network_id = data.vsphere_network.vcenter_network_mgmt_nested.id
  }

  num_cpus = 6
  memory = 24576

  disk {
    size             = 200
    label            = "nsx-manager.lab_vmdk"
    thin_provisioned = true
  }

  clone {
    template_uuid = vsphere_content_library_item.nested_library_nsx_item.id
  }

  vapp {
    properties = {
      nsx_allowSSHRootLogin = "True"
      nsx_cli_audit_passwd_0 = var.nsx_password
      nsx_cli_passwd_0 = var.nsx_password
      nsx_dns1_0 = var.vcenter_underlay.networks.vsphere.management.external_gw_ip
      nsx_gateway_0 = var.vcenter_underlay.networks.vsphere.management.gateway
      nsx_hostname = "nsx-manager"
      nsx_ip_0 = var.vcenter_underlay.networks.vsphere.management.nsx_ip
      nsx_isSSHEnabled = "True"
      nsx_netmask_0 = var.vcenter_underlay.networks.vsphere.management.netmask
      nsx_ntp_0 = var.vcenter_underlay.networks.vsphere.management.external_gw_ip
      nsx_passwd_0 = var.nsx_password
      nsx_role = "NSX Manager"
      nsx_swIntegrityCheck = "False"
    }
  }
}

resource "null_resource" "wait_nsx" {
  depends_on = [vsphere_virtual_machine.nsx_medium]

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${var.vcenter_underlay.networks.vsphere.management.nsx_ip}); do echo \"Attempt $count: Waiting for NSX Manager to be reachable...\"; sleep 30 ; count=$((count+1)) ;  if [ \"$count\" = 60 ]; then echo \"ERROR: Unable to connect to NSX Manager\" ; exit 1 ; fi ; done"
  }
}