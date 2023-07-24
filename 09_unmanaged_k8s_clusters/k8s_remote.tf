data "template_file" "environment_variables" {
  template = file("templates/environment_variables.json.template")
  vars = {
    vsphere_nested_password = var.vsphere_nested_password
    ubuntu_password = var.ubuntu_password
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
  }
}


resource "null_resource" "tf_k8s" {

  connection {
    host = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    source = var.ubuntu_ova_path
    destination = "/home/ubuntu/${basename(var.ubuntu_ova_path)}"
  }

  provisioner "file" {
    source = "/root/unmanaged_k8s_clusters.json"
    destination = "/home/ubuntu/unmanaged_k8s_clusters.json"
  }

  provisioner "file" {
    source = "tf_remote_k8s"
    destination = "tf_remote_k8s"
  }

  provisioner "file" {
    content = data.template_file.environment_variables.rendered
    destination = "/home/ubuntu/.environment_variables.json"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir .kube",
      "mkdir ako_config_maps",
      "cd tf_remote_k8s",
      "terraform init",
      "terraform apply -auto-approve -var-file=/home/ubuntu/unmanaged_k8s_clusters.json -var-file=/home/ubuntu/.environment_variables.json"
    ]
  }
}