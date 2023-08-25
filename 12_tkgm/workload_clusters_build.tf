resource "null_resource" "govc_bash_script_workloads" {
  count = length(var.tkg.clusters.workloads)

  provisioner "local-exec" {
    command = "cat > govc_workload${count.index + 1 }.sh <<EOL\n${data.template_file.govc_bash_script_workloads[count.index].rendered}\nEOL"
  }

  provisioner "local-exec" {
    command = "/bin/bash govc_workload${count.index + 1 }.sh"
  }

}

resource "null_resource" "builds" {
  depends_on = [null_resource.govc_bash_script_workloads]
  count = length(var.tkg.clusters.workloads)

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "tanzu cluster create ${var.tkg.clusters.workloads[count.index].name} -f workload${count.index + 1 }.yml -v 6"
    ]
  }
}