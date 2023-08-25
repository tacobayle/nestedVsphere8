resource "null_resource" "supervisor" {

  provisioner "local-exec" {
    command = "/bin/bash /nestedVsphere8/11_vsphere_with_tanzu/01_supervisor.sh"
  }
}

data "template_file" "tkc_clusters" {
  template = file("templates/tkc.yml.template")
  count = length(var.tanzu.tkc_clusters)
  vars = {
    name = var.tanzu.tkc_clusters[count.index].name
    namespace_ref = var.tanzu.tkc_clusters[count.index].namespace_ref
    k8s_version = var.tanzu.tkc_clusters[count.index].k8s_version
    control_plane_count = var.tanzu.tkc_clusters[count.index].control_plane_count
    control_plane_class = var.tanzu.tkc_clusters[count.index].control_plane_class
    workers_count = var.tanzu.tkc_clusters[count.index].workers_count
    workers_class = var.tanzu.tkc_clusters[count.index].workers_class
    cni = var.tanzu.tkc_clusters[count.index].cni
    services_cidrs = jsonencode(var.tanzu.tkc_clusters[count.index].services_cidrs)
    pods_cidrs = jsonencode(var.tanzu.tkc_clusters[count.index].pods_cidrs)
  }
}

data "template_file" "tkc_clusters_script" {
  template = file("templates/tkc.sh.template")
  vars = {
    kubectl_password = var.vsphere_nested_password
    sso_domain_name = var.vsphere_nested.sso.domain_name
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
    docker_registry_email = var.docker_registry_email
  }
}

resource "null_resource" "prep_tkc" {

  depends_on = [null_resource.supervisor]

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    source = "/root/api_server_cluster_endpoint.json"
    destination = "/home/ubuntu/tanzu/api_server_cluster_endpoint.json"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -k https://$(jq -c -r .api_server_cluster_endpoint /home/ubuntu/tanzu/api_server_cluster_endpoint.json)/wcp/plugin/linux-amd64/vsphere-plugin.zip -o ./vsphere-plugin.zip",
      "unzip -o vsphere-plugin.zip",
      "mv vsphere-plugin.zip /tmp/vsphere-plugin.zip"
    ]
  }

  provisioner "file" {
    source = "/nestedVsphere8/11_vsphere_with_tanzu/templates/deployment1.yml"
    destination = "/home/ubuntu/tanzu-yaml/deployment1.yml"
  }

  provisioner "file" {
    source = "/nestedVsphere8/11_vsphere_with_tanzu/templates/deployment2.yml"
    destination = "/home/ubuntu/tanzu-yaml/deployment2.yml"
  }

  provisioner "file" {
    source = "/nestedVsphere8/11_vsphere_with_tanzu/templates/deployment3.yml"
    destination = "/home/ubuntu/tanzu-yaml/deployment3.yml"
  }

  provisioner "file" {
    source = "/nestedVsphere8/11_vsphere_with_tanzu/templates/svc1.yml"
    destination = "/home/ubuntu/tanzu-yaml/svc1.yml"
  }

  provisioner "file" {
    source = "/nestedVsphere8/11_vsphere_with_tanzu/templates/svc2.yml"
    destination = "/home/ubuntu/tanzu-yaml/svc2.yml"
  }

  provisioner "file" {
    source = "/nestedVsphere8/11_vsphere_with_tanzu/templates/svc3.yml"
    destination = "/home/ubuntu/tanzu-yaml/svc3.yml"
  }

  provisioner "file" {
    source = "/root/tanzu_wo_nsx.json"
    destination = "/home/ubuntu/tanzu_wo_nsx.json"
  }

  provisioner "file" {
    content = data.template_file.tkc_clusters_script.rendered
    destination = "/home/ubuntu/tkc/tkc.sh"
  }

  provisioner "file" {
    source = "templates/tkc_destroy.sh"
    destination = "/home/ubuntu/tkc/tkc_destroy.sh"
  }

}


resource "null_resource" "transfer_tkc_yaml_files" {

  depends_on = [null_resource.prep_tkc]
  count = length(var.tanzu.tkc_clusters)


  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }


  provisioner "file" {
    content = data.template_file.tkc_clusters[count.index].rendered
    destination = "/home/ubuntu/tkc/tkc-${count.index + 1}.yml"
  }

}

resource "time_sleep" "wait_cl_sync" {
  depends_on = [null_resource.transfer_tkc_yaml_files]
  create_duration = "60s"
}

resource "null_resource" "run_tkc" {

  depends_on = [time_sleep.wait_cl_sync]

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash /home/ubuntu/tkc/tkc.sh"
    ]
  }
}