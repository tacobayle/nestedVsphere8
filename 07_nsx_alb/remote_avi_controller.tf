data "template_file" "environment_variables" {
  template = file("templates/environment_variables.json.template")
  vars = {
    vcenter_password = var.vsphere_nested_password
    avi_password = var.avi_password
  }
}

resource "null_resource" "tf_avi_controller" {

  connection {
    host = var.vcenter_underlay.networks.vsphere.management.external_gw_ip
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }


  # restart here

  provisioner "file" {
    source = var.avi.content_library.ova_location
    destination = basename(var.avi.content_library.ova_location)
  }

  provisioner "file" {
    source = "../../avi.json"
    destination = "avi.json"
  }

  provisioner "file" {
    source = "tf_remote"
    destination = "tf_remote_avi_controller"
  }

  provisioner "file" {
    content = data.template_file.environment_variables.rendered
    destination = ".environment_variables.json"
  }

  provisioner "remote-exec" {
    inline = [
      "cd tf_remote_avi_controller",
      "terraform init",
      "terraform apply -auto-approve -var-file=../avi.json -var-file=../.environment_variables.json"
    ]
  }
}