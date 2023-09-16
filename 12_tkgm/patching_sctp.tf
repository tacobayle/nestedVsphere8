data "template_file" "template_patching_sctp" {
  template = file("templates/workload_cluster_patching_sctp.sh.template")
  count = length(var.tkg.clusters.workloads)
  vars = {
    name = var.tkg.clusters.workloads[count.index].name
    file_ips = "${var.tkg.clusters.workloads[count.index].name}-${count.index + 1}.txt"
    private_key=basename(var.tkg.clusters.private_key_path)
    ssh_username = var.tkg.clusters.workloads[count.index].ssh_username
  }
}


resource "null_resource" "set_initial_state" {
  depends_on = [null_resource.create_workload_clusters]
  count = length(var.tkg.clusters.workloads)

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "echo \"0\" > /root/sctp_patching_state.txt"
  }
}

resource "null_resource" "workload_patching_sctp" {
  depends_on = [null_resource.create_workload_clusters, null_resource.set_initial_state]
  count = length(var.tkg.clusters.workloads)
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "while [[ $(cat /root/sctp_patching_state.txt) != \"${count.index}\" ]]; do echo \"${count.index} is waiting...\";sleep 5;done"
  }

  provisioner "file" {
    content = data.template_file.template_patching_sctp[count.index].rendered
    destination = "/home/ubuntu/tkgm/workload_clusters/patching${count.index + 1}.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash /home/ubuntu/tkgm/workload_clusters/patching${count.index + 1}.sh"
    ]
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "echo \"${count.index+1}\" > /root/sctp_patching_state.txt"
  }

}