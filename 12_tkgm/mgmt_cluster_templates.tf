data "template_file" "govc_bash_script_mgmt" {
  template = file("templates/govc_mgmt.sh.template")
  vars = {
    dc = var.vsphere_nested.datacenter
    cluster = var.vsphere_nested.cluster
    vsphere_url = "administrator@${var.vsphere_nested.sso.domain_name}:${var.vsphere_nested_password}@${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
    mgmt_folder = var.tkg.clusters.management.name
    vcenter_resource_pool = var.tkg.clusters.management.name
  }
}

data "template_file" "mgmt" {
  template = file("templates/mgmt_cluster.yml.template")
  vars = {
    avi_cloud_name = var.tkg.clusters.management.avi_cloud_name
    avi_controller_ip = cidrhost(var.tkg.avi_cidr, var.tkg.avi_ip)
    avi_control_plane_network = var.tkg.clusters.management.avi_control_plane_network
    avi_control_plane_network_cidr = local.avi_control_plane_network_cidr
    avi_data_network = var.tkg.clusters.management.avi_data_network
    avi_data_network_cidr = local.avi_data_network_cidr
    avi_mgmt_cluster_control_plane_vip_network_cidr = local.avi_mgmt_cluster_control_plane_vip_network_cidr
    avi_mgmt_cluster_control_plane_vip_network_name = var.tkg.clusters.management.avi_mgmt_cluster_control_plane_vip_network_name
    avi_mgmt_cluster_vip_network_name = var.tkg.clusters.management.avi_mgmt_cluster_vip_network_name
    avi_mgmt_cluster_vip_network_cidr = local.avi_mgmt_cluster_vip_network_cidr
    avi_management_cluster_service_engine_group = var.tkg.clusters.management.avi_management_cluster_service_engine_group
    avi_service_engine_group = var.tkg.clusters.management.avi_service_engine_group
    name = var.tkg.clusters.management.name
    cluster_cidr = var.tkg.clusters.management.cluster_cidr
    service_cidr = var.tkg.clusters.management.service_cidr
    avi_password_base64 = base64encode(var.avi_password)
    avi_username = var.tkg.clusters.management.avi_username
    datacenter = var.vcenter.datacenter
    cluster = var.vcenter.cluster
    vcenter_folder = var.tkg.clusters.management.name
    vcenter_resource_pool = var.tkg.clusters.management.name
    vcenter_password_base64 = base64encode(var.vcenter_password)
    vsphere_server = "${var.vcenter.name}.${var.dns.domain}"
    ssh_public_key = file(var.tkg.clusters.management.public_key_path)
    vsphere_tls_thumbprint = file("vcenter_finger_print.txt")
    vsphere_username = "administrator@${var.vcenter.sso.domain_name}"
    vsphere_network = var.tkg.clusters.management.vsphere_network
    control_plane_disk = var.tkg.clusters.management.control_plane_disk
    control_plane_memory = var.tkg.clusters.management.control_plane_memory
    control_plane_cpu = var.tkg.clusters.management.control_plane_cpu
    worker_disk = var.tkg.clusters.management.worker_disk
    worker_memory = var.tkg.clusters.management.worker_memory
    worker_cpu = var.tkg.clusters.management.worker_cpu
    avi_cert_base64 = base64encode(file("avi.cert"))
  }
}

resource "null_resource" "transfer_files" {

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    content = data.template_file.mgmt.rendered
    destination = "/home/ubuntu/tkgm/mgmt_cluster/tkg-cluster-mgmt.yml"
  }

}