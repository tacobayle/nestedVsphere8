

data "template_file" "mgmt" {
  template = file("templates/mgmt_cluster.yml.template")
  vars = {
    avi_cloud_name = var.tkg.clusters.management.avi_cloud_name
    avi_controller_ip = var.vsphere_underlay.networks.vsphere.management.avi_nested_ip
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
    datacenter = var.vsphere_nested.datacenter
    datastore = var.tkg.clusters.management.datastore_ref
    cluster = var.tkg.clusters.management.cluster_ref
    vcenter_folder = var.tkg.clusters.management.name
    vcenter_resource_pool = var.tkg.clusters.management.name
    vcenter_password_base64 = base64encode(var.vsphere_nested_password)
    vsphere_server = "${var.vsphere_nested.vcsa_name}.${var.external_gw.bind.domain}"
    ssh_public_key = file(var.tkg.clusters.public_key_path)
    vsphere_tls_thumbprint = file("/root/vcenter_finger_print.txt")
    vsphere_username = "administrator@${var.vsphere_nested.sso.domain_name}"
    vsphere_network = var.tkg.clusters.management.vsphere_network
    control_plane_disk = var.tkg.clusters.management.control_plane_disk
    control_plane_memory = var.tkg.clusters.management.control_plane_memory
    control_plane_cpu = var.tkg.clusters.management.control_plane_cpu
    worker_disk = var.tkg.clusters.management.worker_disk
    worker_memory = var.tkg.clusters.management.worker_memory
    worker_cpu = var.tkg.clusters.management.worker_cpu
    avi_cert_base64 = base64encode(file("/root/avi_cert.txt"))
  }
}

resource "null_resource" "transfer_mgmt_file" {

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


resource "null_resource" "create_mgmt_cluster" {
  depends_on = [null_resource.install_docker, null_resource.tkg_install, null_resource.govc_image_creation_run, null_resource.govc_mgmt_run]

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "tanzu management-cluster create ${var.tkg.clusters.management.name} -f /home/ubuntu/tkgm/mgmt_cluster/tkg-cluster-mgmt.yml -v 6"
    ]
  }

}
