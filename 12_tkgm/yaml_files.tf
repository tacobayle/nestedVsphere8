resource "null_resource" "transfer_cnf_sctp_files" {

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = "yaml/sctp_client.yml"
    destination = "/home/ubuntu/yaml-files/sctp_client.yml"
  }

  provisioner "file" {
    source      = "yaml/svc_sctp.yml"
    destination = "/home/ubuntu/yaml-files/svc_sctp.yml"
  }

  provisioner "file" {
    source      = "yaml/k8s_sctp_deployment.yml"
    destination = "/home/ubuntu/yaml-files/k8s_sctp_deployment.yml"
  }

}

data "template_file" "workload_values" {
  count = length(var.tkg.clusters.workloads)
  template = file("templates/values.1.10.2.yaml.template")
  vars = {
    clusterName = var.tkg.clusters.workloads[count.index].name
    cniPlugin = var.tkg.clusters.workloads[count.index].cni
    networkName = var.avi.config.ako.vip_network_name_ref
    cidr = var.avi.config.ako.vip_network_cidr
    default_peer_label = var.avi.config.cloud.contexts[0].routing_options[0].label
    serviceType = var.avi.config.ako.service_type
    serviceEngineGroupName = var.tkg.clusters.workloads[count.index].name
    controllerVersion = var.avi.controller.version
    cloudName = var.avi.ako.cloud_name
    controllerHost = var.vsphere_underlay.networks.vsphere.management.avi_nested_ip
    tenantName = var.tkg.clusters.workloads[count.index].name
    password = var.avi_password
  }
}

resource "null_resource" "transfer_ako_values_files" {
  count = length(var.tkg.clusters.workloads)

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    content = data.template_file.workload_values[count.index].rendered
    destination = "/home/ubuntu/tkgm/workload_clusters/ako-values-cluster{count.index + 1}.yml"
  }
}

resource "null_resource" "yaml_build_and_transfer" {
  provisioner "local-exec" {
    command = "/bin/bash /nestedVsphere8/12_tkgm/yaml_files.sh"
  }
}


