resource "null_resource" "retrieve_vcenter_finger_print" {
  provisioner "local-exec" {
    command = "rm -f /root/vcenter_finger_print.txt ; echo | openssl s_client -connect {var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}:443 | openssl x509 -fingerprint -noout |  cut -d\"=\" -f2 | tee /root/vcenter_finger_print.txt > /dev/null "
  }
}


resource "null_resource" "tkg_transfer" {

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
      "tar -xf /home/ubuntu/tkgm/bin/${basename(var.tkg.tanzu_bin_location)}",
      "cd cli",
      "sudo install core/v0.25.0/tanzu-core-linux_amd64 /usr/local/bin/tanzu",
      "tanzu init",
      "tanzu plugin sync",
      "cd ~",
      "gunzip ${basename(var.tkg.k8s_bin_location)}",
      "chmod ugo+x kubectl-linux-v1.23.8+vmware.2",
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