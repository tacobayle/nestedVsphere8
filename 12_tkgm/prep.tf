resource "null_resource" "install_docker" {
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "sudo mkdir -p /etc/apt/keyrings",
      "sudo rm -f /etc/apt/keyrings/docker.gpg",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "sudo rm -f /etc/apt/sources.list.d/docker.list",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin",
      "sudo groupadd docker",
      "sudo usermod -aG docker $USER"
    ]
  }
}

resource "null_resource" "tkg_transfer" {
  depends_on = [null_resource.install_docker]
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = "/root/${basename(var.tkg.tanzu_bin_location)}"
    destination = "/home/ubuntu/tkgm/bin/${basename(var.tkg.tanzu_bin_location)}"
  }

  provisioner "file" {
    source      = "/root/${basename(var.tkg.k8s_bin_location)}"
    destination = "/home/ubuntu/tkgm/bin/${basename(var.tkg.k8s_bin_location)}"
  }
}

resource "null_resource" "tkg_install" {
  depends_on = [null_resource.tkg_transfer]
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "tar_output=$(tar -xvf /home/ubuntu/tkgm/bin/$(basename ${var.tkg.tanzu_bin_location})",
      "tanzu_directory=$(echo $tar_output | cut -d"/" -f1)",
      "sudo install /home/ubuntu/$tanzu_directory/tanzu-cli-linux_amd64 /usr/local/bin/tanzu",
      "tanzu config eula  accept",
      "tanzu plugin install --group vmware-tkg/default:${var.tkg.version}",
      "gunzip /home/ubuntu/tkgm/bin/$(basename ${var.tkg.k8s_bin_location})",
      "file_path=\"/home/ubuntu/tkgm/bin/$(basename ${var.tkg.k8s_bin_location})\"",
      "file_path_unziped=$${file_path%.*}",
      "chmod ugo+x $${file_path_unziped}",
      "sudo install $${file_path_unziped} /usr/local/bin/kubectl"
    ]
  }
}

data "template_file" "govc_image_creation" {
  template = file("templates/govc_image_creation.sh.template")
  vars = {
    dc = var.vsphere_nested.datacenter
    cluster = var.vsphere_nested.cluster
    vsphere_url = "administrator@${var.vsphere_nested.sso.domain_name}:${var.vsphere_nested_password}@${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
    ova_folder_template = var.tkg.ova_folder_template
    ova_basename = basename(var.tkg.ova_location)
    ova_network = var.tkg.ova_network
    cluster = var.vsphere_nested.cluster
  }
}

resource "null_resource" "govc_image_creation_run" {


  provisioner "local-exec" {
    command = "cat > /root/govc_image_creation.sh <<EOL\n${data.template_file.govc_image_creation.rendered}\nEOL"
  }


  provisioner "local-exec" {
    command = "/bin/bash /root/govc_image_creation.sh"
  }

}

data "template_file" "govc_mgmt" {
  template = file("templates/govc_mgmt.sh.template")
  vars = {
    dc = var.vsphere_nested.datacenter
    cluster = var.vsphere_nested.cluster
    vsphere_url = "administrator@${var.vsphere_nested.sso.domain_name}:${var.vsphere_nested_password}@${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
    mgmt_folder = var.tkg.clusters.management.name
    vcenter_resource_pool = var.tkg.clusters.management.name
  }
}

data "template_file" "govc_mgmt_destroy" {
  template = file("templates/govc_mgmt_destroy.sh.template")
  vars = {
    dc = var.vsphere_nested.datacenter
    cluster = var.vsphere_nested.cluster
    vsphere_url = "administrator@${var.vsphere_nested.sso.domain_name}:${var.vsphere_nested_password}@${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
    mgmt_folder = var.tkg.clusters.management.name
    vcenter_resource_pool = var.tkg.clusters.management.name
  }
}


resource "null_resource" "govc_mgmt_run" {

  provisioner "local-exec" {
    command = "cat > govc_mgmt.sh <<EOL\n${data.template_file.govc_mgmt.rendered}\nEOL"
  }

  provisioner "local-exec" {
    command = "cat > govc_mgmt_destroy.sh <<EOL\n${data.template_file.govc_mgmt_destroy.rendered}\nEOL"
  }


  provisioner "local-exec" {
    command = "/bin/bash govc_mgmt.sh"
  }

}


data "template_file" "govc_workloads" {
  count = length(var.tkg.clusters.workloads)
  template = file("templates/govc_workers.sh.template")
  vars = {
    dc = var.vsphere_nested.datacenter
    cluster = var.vsphere_nested.cluster
    vsphere_url = "administrator@${var.vsphere_nested.sso.domain_name}:${var.vsphere_nested_password}@${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
    vcenter_folder = var.tkg.clusters.workloads[count.index].name
    vcenter_resource_pool = var.tkg.clusters.workloads[count.index].name
  }
}

data "template_file" "govc_workloads_destroy" {
  count = length(var.tkg.clusters.workloads)
  template = file("templates/govc_workers_destroy.sh.template")
  vars = {
    dc = var.vsphere_nested.datacenter
    cluster = var.vsphere_nested.cluster
    vsphere_url = "administrator@${var.vsphere_nested.sso.domain_name}:${var.vsphere_nested_password}@${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
    vcenter_folder = var.tkg.clusters.workloads[count.index].name
    vcenter_resource_pool = var.tkg.clusters.workloads[count.index].name
  }
}

resource "null_resource" "govc_workloads" {
  count = length(var.tkg.clusters.workloads)

  provisioner "local-exec" {
    command = "cat > govc_workload${count.index + 1 }.sh <<EOL\n${data.template_file.govc_workloads[count.index].rendered}\nEOL"
  }

  provisioner "local-exec" {
    command = "cat > govc_workload${count.index + 1 }_destroy.sh <<EOL\n${data.template_file.govc_workloads_destroy[count.index].rendered}\nEOL"
  }

  provisioner "local-exec" {
    command = "/bin/bash govc_workload${count.index + 1 }.sh"
  }

}