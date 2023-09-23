resource "null_resource" "supervisor" {

  provisioner "local-exec" {
    command = "/bin/bash /nestedVsphere8/11_vsphere_with_tanzu/create_supervisor.sh"
  }
}

data "template_file" "tkc_clusters" {
  template = file("templates/tkc.yml.template")
  count = length(var.tanzu.tkc_clusters)
  vars = {
    name = var.tanzu.tkc_clusters[count.index].name
    namespace_ref = var.tanzu.tkc_clusters[count.index].namespace_ref
    services_cidrs = jsonencode(var.tanzu.tkc_clusters[count.index].services_cidrs)
    pods_cidrs = jsonencode(var.tanzu.tkc_clusters[count.index].pods_cidrs)
    domain = var.external_gw.bind.domain
    k8s_version = var.tanzu.tkc_clusters[count.index].k8s_version
    cluster_count = count.index + 1
    control_plane_count = var.tanzu.tkc_clusters[count.index].control_plane_count
    vm_class = var.tanzu.tkc_clusters[count.index].vm_class
    workers_count = var.tanzu.tkc_clusters[count.index].workers_count
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

data "template_file" "tkc_clusters_destroy_script" {
  template = file("templates/tkc_destroy.sh.template")
  vars = {
    kubectl_password = var.vsphere_nested_password
    sso_domain_name = var.vsphere_nested.sso.domain_name
  }
}

data "template_file" "tanzu_auth_script" {
  template = file("templates/tanzu_auth_supervisor.sh.template")
  vars = {
    kubectl_password = var.vsphere_nested_password
    sso_domain_name = var.vsphere_nested.sso.domain_name
  }
}

data "template_file" "tanzu_auth_script_tkc" {
  template = file("templates/tanzu_auth_tkc.sh.template")
  count = length(var.tanzu.tkc_clusters)
  vars = {
    name = var.tanzu.tkc_clusters[count.index].name
    namespace_ref = var.tanzu.tkc_clusters[count.index].namespace_ref
    kubectl_password = var.vsphere_nested_password
    sso_domain_name = var.vsphere_nested.sso.domain_name
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
    source = "/root/tanzu_wo_nsx.json"
    destination = "/home/ubuntu/tanzu_wo_nsx.json"
  }

  provisioner "file" {
    content = data.template_file.tkc_clusters_script.rendered
    destination = "/home/ubuntu/tkc/tkc.sh"
  }

  provisioner "file" {
    content = data.template_file.tkc_clusters_destroy_script.rendered
    destination = "/home/ubuntu/tkc/tkc_destroy.sh"
  }

  provisioner "file" {
    content = data.template_file.tanzu_auth_script.rendered
    destination = "/home/ubuntu/tanzu/auth_supervisor.sh"
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

  provisioner "file" {
    content = data.template_file.tanzu_auth_script_tkc[count.index].rendered
    destination = "/home/ubuntu/tkc/auth-tkc-${count.index + 1}.sh"
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