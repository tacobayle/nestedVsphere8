resource "null_resource" "retrieve_vcenter_finger_print" {
  provisioner "local-exec" {
    command = "rm -f /root/vcenter_finger_print.txt ; echo | openssl s_client -connect {var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}:443 | openssl x509 -fingerprint -noout |  cut -d\"=\" -f2 | tee /root/vcenter_finger_print.txt > /dev/null "
  }
}

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

  provisioner "file" {
    source      = "/root/${basename(var.tkg.ova_location)}"
    destination = "/home/ubuntu/tkgm/bin/${basename(var.tkg.ova_location)}"
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
      "tar_output=$(tar -xvf /home/ubuntu/tkgm/bin/${basename(var.tkg.tanzu_bin_location)})",
      "tanzu_directory=$(echo $tar_output | cut -d"/" -f1)",
      "install /home/ubuntu/tkgm/bin/$tanzu_directory/tanzu-cli-linux_amd64 /usr/local/bin/tanzu",
      "tanzu plugin install --group vmware-tkg/default:${var.tkg.version}",
      "echo \"    eulaStatus: accepted\" | tee -a home/ubuntu/.config/tanzu/config-ng.yaml",

      "gunzip /home/ubuntu/tkgm/bin/${basename(var.tkg.k8s_bin_location)}",
      "file_path=\"/home/ubuntu/tkgm/bin/${basename(var.tkg.k8s_bin_location)}\"",
      "file_path_unziped=bar=$${file_path%.*}",
      "chmod ugo+x $${file_unziped}",
      "sudo install $${file_unziped} /usr/local/bin/kubectl",




      "sudo install kubectl-linux-v1.23.8+vmware.2 /usr/local/bin/kubectl",
      "cd ~/cli",
      "gunzip ytt-linux-amd64-v0.41.1+vmware.1.gz",
      "chmod ugo+x ytt-linux-amd64-v0.41.1+vmware.1",
      "sudo mv ./ytt-linux-amd64-v0.41.1+vmware.1 /usr/local/bin/ytt",
      "gunzip kapp-linux-amd64-v0.49.0+vmware.1.gz",
      "sudo mv ./kapp-linux-amd64-v0.49.0+vmware.1 /usr/local/bin/kapp",
      "gunzip kbld-linux-amd64-v0.34.0+vmware.1.gz",
      "chmod ugo+x kbld-linux-amd64-v0.34.0+vmware.1",
      "sudo mv ./kbld-linux-amd64-v0.34.0+vmware.1 /usr/local/bin/kbld",
      "gunzip imgpkg-linux-amd64-v0.29.0+vmware.1.gz",
      "chmod ugo+x imgpkg-linux-amd64-v0.29.0+vmware.1",
      "sudo mv ./imgpkg-linux-amd64-v0.29.0+vmware.1 /usr/local/bin/imgpkg"
    ]
  }
}

