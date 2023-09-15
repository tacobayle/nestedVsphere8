data "template_file" "workload" {
  count = length(var.tkg.clusters.workloads)
  template = file("templates/workload_clusters.yml.template")
  vars = {
    name = var.tkg.clusters.workloads[count.index].name
    cni = var.tkg.clusters.workloads[count.index].cni
    antrea_node_port_local = var.tkg.clusters.workloads[count.index].antrea_node_port_local
    cluster_cidr = var.tkg.clusters.workloads[count.index].cluster_cidr
    avi_control_plane_ha_provider = var.tkg.clusters.workloads[count.index].avi_control_plane_ha_provider
    service_cidr = var.tkg.clusters.workloads[count.index].service_cidr
    datacenter = var.vsphere_nested.datacenter
    vcenter_folder = var.tkg.clusters.workloads[count.index].name
    cluster = var.vsphere_nested.cluster
    vcenter_resource_pool = var.tkg.clusters.workloads[count.index].name
    vcenter_password_base64 = base64encode(var.vsphere_nested_password)
    vsphere_network = var.tkg.clusters.workloads[count.index].vsphere_network
    vsphere_server = "${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
    vsphere_username = "administrator@${var.vsphere_nested.sso.domain_name}"
    worker_disk = var.tkg.clusters.workloads[count.index].worker_disk
    worker_memory = var.tkg.clusters.workloads[count.index].worker_memory
    worker_cpu = var.tkg.clusters.workloads[count.index].worker_cpu
    worker_count = var.tkg.clusters.workloads[count.index].worker_count
    control_plane_disk = var.tkg.clusters.workloads[count.index].control_plane_disk
    control_plane_memory = var.tkg.clusters.workloads[count.index].control_plane_memory
    control_plane_cpu = var.tkg.clusters.workloads[count.index].control_plane_cpu
    control_plane_count = var.tkg.clusters.workloads[count.index].control_plane_count
    ssh_public_key = file(var.tkg.clusters.public_key_path)
    vsphere_tls_thumbprint = file("/root/vcenter_finger_print.txt")
  }
}



resource "null_resource" "transfer_templates" {
  count = length(var.tkg.clusters.workloads)
  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }


  provisioner "file" {
    content = data.template_file.workload[count.index].rendered
    destination = "/home/ubuntu/tkgm/workload_clusters/workload${count.index + 1 }.yml"
  }
}


resource "null_resource" "create_workload_clusters" {
  depends_on = [null_resource.govc_workloads, null_resource.create_mgmt_cluster]
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
      "tanzu cluster create ${var.tkg.clusters.workloads[count.index].name} -f /home/ubuntu/tkgm/workload_clusters/workload${count.index + 1 }.yml -v 6"
    ]
  }
}