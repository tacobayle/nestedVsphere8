
resource "null_resource" "vcenter_install" {
  depends_on = [null_resource.esxi_customization_disk]

  provisioner "local-exec" {
    command = "/bin/bash 11_vCenter_iso_extract.sh"
  }
}

resource "null_resource" "wait_vsca" {
  depends_on = [null_resource.vcenter_install]

  provisioner "local-exec" {
    command = "count=1 ; until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip}); do echo \"Attempt $count: Waiting for vCenter to be reachable...\"; sleep 10 ; count=$((count+1)) ;  if [ \"$count\" = 30 ]; then echo \"ERROR: Unable to connect to vCenter\" ; exit 1 ; fi ; done"
  }
}



// see nested_vcenter_config_dual_attached or nested_vcenter_config_single_attached


#data "template_file" "expect_script" {
#  template = file("${path.module}/templates/expect_script.sh.template")
#  vars = {
#    vcenter_username        = "administrator"
#    vcenter_sso_domain = var.vsphere_nested.sso.domain_name
#    vsphere_nested_password = var.vsphere_nested_password
#    vcenter_fqdn = "${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
#    vcenter_dc = var.vsphere_nested.datacenter
#    vcenter_cluster = var.vsphere_nested.cluster
#  }
#}
#
#
#resource "null_resource" "execute_expect_script" {
#  depends_on = [null_resource.dual_uplink_update_multiple_vds, null_resource.vsan_config]
#  connection {
#    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
#    type        = "ssh"
#    agent       = false
#    user        = "ubuntu"
#    private_key = file("/root/.ssh/id_rsa")
#  }
#
#  provisioner "file" {
#    content = data.template_file.expect_script.rendered
#    destination = "/tmp/vcenter_expect.sh"
#  }
#
#
#  provisioner "remote-exec" {
#    inline      = [
#      "chmod u+x /tmp/vcenter_expect.sh",
#      "/tmp/vcenter_expect.sh"
#    ]
#  }
#}