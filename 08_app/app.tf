

resource "null_resource" "tf_app" {

  connection {
    host = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    source = "/root/app.json"
    destination = "/home/ubuntu/app.json"
  }

  provisioner "file" {
    source = "tf_remote_app"
    destination = "tf_remote_app"
  }

  provisioner "file" {
    content = data.template_file.environment_variables.rendered
    destination = "/home/ubuntu/.environment_variables.json"
  }

  provisioner "file" {
    content = data.template_file.environment_variables.rendered
    destination = "/home/ubuntu/.environment_variables_nsx.json"
  }

  provisioner "remote-exec" {
    inline = [
      "cd tf_remote_app",
      "terraform init",
      "terraform apply -auto-approve -var-file=/home/ubuntu/app.json -var-file=/home/ubuntu/.environment_variables.json"
    ]
  }
}

resource "null_resource" "nsx_lb" {
  count = var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd" ? 1 : 0
  depends_on = [null_resource.tf_app]
  provisioner "local-exec" {
    command = "/bin/bash /nestedVsphere8/08_app/nsx_lbs.sh"
  }
}