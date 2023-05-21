resource "vsphere_content_library" "nested_library_se" {
  name            = var.nsx_alb_se_cl
  storage_backing = [data.vsphere_datastore.datastore_nested.id]
}

resource "null_resource" "wait_https_controller" {

  provisioner "local-exec" {
    command = "until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip}); do echo 'Waiting for Avi Controllers to be ready'; sleep 60 ; done"
  }
}

resource "null_resource" "ansible_hosts_avi_header_1" {
  provisioner "local-exec" {
    command = "echo '---' | tee hosts_avi; echo 'all:' | tee -a hosts_avi ; echo '  children:' | tee -a hosts_avi; echo '    controller:' | tee -a hosts_avi; echo '      hosts:' | tee -a hosts_avi"
  }
}

resource "null_resource" "ansible_hosts_avi_controllers" {
  depends_on = [null_resource.ansible_hosts_avi_header_1]
  provisioner "local-exec" {
    command = "echo '        ${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip}:' | tee -a hosts_avi "
  }
}

data "template_file" "traffic_gen" {
  template = file("templates/traffic_gen.sh.template")
  vars = {
    controllerPrivateIp = jsonencode(var.vsphere_underlay.networks.vsphere.management.avi_nested_ip)
    avi_password = jsonencode(var.avi_password)
    avi_username = "admin"
  }
}

resource "null_resource" "transfer_traffic_gen" {
  depends_on = [null_resource.alb_ansible_config]

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    content = data.template_file.traffic_gen.rendered
    destination = "/home/ubuntu/traffic_gen.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /home/ubuntu/traffic_gen.sh",
      "(crontab -l 2>/dev/null; echo \"* * * * * /home/ubuntu/traffic_gen.sh\") | crontab -"
    ]
  }

}

#
# Need to update Avi UI/API cert.
#

resource "null_resource" "dump_alb_cert_locally" {
  depends_on = [null_resource.alb_ansible_config]
  provisioner "local-exec" {
    command = "echo -n | openssl s_client -connect ${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip}:443 -servername ${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip} | openssl x509 | tee /root/${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip}.cert"
  }
}