resource "null_resource" "supervisor" {

  provisioner "local-exec" {
    command = "/bin/bash /nestedVsphere8/11_tanzu_on_vsphere/01_supervisor.sh"
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
  count = length(var.tanzu.tkc_clusters)
  vars = {
    KUBECTL_VSPHERE_PASSWORD = var.vsphere_nested_password
    SSO_DOMAIN_NAME = var.vsphere_nested.sso.domain_name
  }
}

resource "null_resource" "prep_tkc" {

  depends_on = [null_resource.supervisor]

  connection {
    host = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type = "ssh"
    agent = false
    user = "tanzu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    source = "/root/api_server_cluster_endpoint.json"
    destination = "/home/tanzu/api_server_cluster_endpoint.json"
  }

  provisioner "file" {
    source = "/root/tanzu_wo_nsx.json"
    destination = "/home/tanzu/tanzu_wo_nsx.json"
  }

  provisioner "file" {
    content = data.template_file.tkc_clusters_script.rendered
    destination = "/home/tanzu/tkc.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir tkc",
      "curl -k https://$(jq -c -r .api_server_cluster_endpoint /home/tanzu/api_server_cluster_endpoint.json)/wcp/plugin/linux-amd64/vsphere-plugin.zip -o ./vsphere-plugin.zip",
      "unzip vsphere-plugin.zip"
    ]
  }
}


resource "null_resource" "transfer_tkc" {

  depends_on = [null_resource.prep_tkc]
  count = length(var.tanzu.tkc_clusters)


  connection {
    host = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type = "ssh"
    agent = false
    user = "tanzu"
    private_key = file("/root/.ssh/id_rsa")
  }


  provisioner "file" {
    content = data.template_file.tkc_clusters[count.index].rendered
    destination = "/home/tanzu/tkc/tkc-${count.index + 1}"
  }

}

resource "null_resource" "run_tkc" {

  depends_on = [null_resource.transfer_tkc]


  connection {
    host = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type = "ssh"
    agent = false
    user = "tanzu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "bin/bash /home/tanzu/tkc.sh"
    ]
  }
}