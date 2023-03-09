data "template_file" "environment_variables" {
  template = file("templates/environment_variables.json.template")
  vars = {
    vsphere_nested_password = var.vsphere_nested_password
    avi_password = var.avi_password
    ubuntu_password = var.ubuntu_password
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

  provisioner "file" {
    source = var.avi_ova_path
    destination = "/home/ubuntu/${basename(var.avi_ova_path)}"
  }

  provisioner "file" {
    source = var.ubuntu_ova_path
    destination = "/home/ubuntu/${basename(var.ubuntu_ova_path)}"
  }

  provisioner "file" {
    source = "/root/avi1.json"
    destination = "/home/ubuntu/avi1.json"
  }

  provisioner "file" {
    source = "tf_remote"
    destination = "tf_remote_avi_controller"
  }

  provisioner "file" {
    content = data.template_file.environment_variables.rendered
    destination = "/home/ubuntu/.environment_variables.json"
  }

  provisioner "remote-exec" {
    inline = [
      "cd tf_remote_avi_controller",
      "terraform init",
      "terraform apply -auto-approve -var-file=/home/ubuntu/avi1.json -var-file=/home/ubuntu/.environment_variables.json"
    ]
  }
}