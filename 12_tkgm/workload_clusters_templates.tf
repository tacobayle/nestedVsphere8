data "template_file" "workload" {
  depends_on = [null_resource.retrieve_vcenter_finger_print]
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
    ssh_public_key = file(var.tkg.clusters.workloads[count.index].public_key_path)
    vsphere_tls_thumbprint = file("/root/vcenter_finger_print.txt")
  }
}

data "template_file" "govc_bash_script_workloads" {
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