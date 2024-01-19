data "template_file" "k8s_masters_userdata" {
  count = length(var.unmanaged_k8s.masters_ips)
  template = file("${path.module}/userdata/k8s.userdata")
  vars = {
    username     = var.k8s.username
    hostname     = "${var.k8s.master_basename}-1"
    password      = var.ubuntu_password
    pubkey       = file("/home/ubuntu/.ssh/id_rsa.pub")
    netplan_file  = var.k8s.netplan_file
    prefix = split("/", var.unmanaged_k8s.masters_cidr[count.index])[1]
    ip = var.unmanaged_k8s.masters_ips[count.index]
    default_gw = var.unmanaged_k8s.masters_gw[count.index]
    dns = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
  }
}

resource "vsphere_virtual_machine" "masters" {
  count = length(var.unmanaged_k8s.masters_ips)
  name             = "${var.unmanaged_k8s.masters_cluster_name[count.index]}-${var.k8s.master_basename}-1"
  datastore_id     = data.vsphere_datastore.datastore_nested_masters[count.index].id
  resource_pool_id = data.vsphere_resource_pool.resource_pool_nested_masters[count.index].id
  folder           = vsphere_folder.k8s[count.index].path

  network_interface {
    network_id = data.vsphere_network.k8s_masters_networks[count.index].id
  }

  num_cpus = var.k8s.master_cpu
  memory = var.k8s.master_memory
  guest_id = "ubuntu64Guest"
  wait_for_guest_net_timeout = 10

  disk {
    size             = var.k8s.master_disk
    label            = "${var.k8s.master_basename}-1.lab_vmdk"
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  clone {
    template_uuid = vsphere_content_library_item.nested_library_k8s_unmanaged_item.id
  }

  vapp {
    properties = {
      hostname    = "${var.k8s.master_basename}-1"
      public-keys = file("/home/ubuntu/.ssh/id_rsa.pub")
      user-data   = base64encode(data.template_file.k8s_masters_userdata[count.index].rendered)
    }
  }

  connection {
    host        = var.unmanaged_k8s.masters_ips[count.index]
    type        = "ssh"
    agent       = false
    user        = var.k8s.username
    private_key = file("/home/ubuntu/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }
}

resource "null_resource" "clear_ssh_keys_masters" {

  depends_on = [vsphere_virtual_machine.masters]
  count = length(var.unmanaged_k8s.masters_ips)

  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/${var.k8s.username}/.ssh/known_hosts\" -R \"${var.unmanaged_k8s.masters_ips[count.index]}\" || true"
  }
}

data "template_file" "k8s_bootstrap_master" {
  count = length(var.unmanaged_k8s.masters_ips)
  template = file("${path.module}/templates/k8s_bootstrap_master.template")
  vars = {
    docker_registry_username = var.docker_registry_username
    K8s_pod_cidr = var.k8s.pod_cidr
    K8s_version = var.unmanaged_k8s.masters_version[count.index]
    Docker_version = var.k8s.docker_version
    docker_registry_password = var.docker_registry_password
    cni_name = var.unmanaged_k8s.masters_cni[count.index]
    cni_version = var.unmanaged_k8s.masters_cni_version[count.index]
  }
}

resource "null_resource" "k8s_bootstrap_master" {
  depends_on = [null_resource.clear_ssh_keys_masters]
  count = length(var.unmanaged_k8s.masters_ips)


  connection {
    host        = var.unmanaged_k8s.masters_ips[count.index]
    type = "ssh"
    agent = false
    user        = var.k8s.username
    private_key = file("/home/ubuntu/.ssh/id_rsa")
  }
  provisioner "file" {
    content = data.template_file.k8s_bootstrap_master[count.index].rendered
    destination = "k8s_bootstrap_master.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo /bin/bash k8s_bootstrap_master.sh"]
  }
}

resource "null_resource" "copy_join_command_to_tf" {

  depends_on = [null_resource.k8s_bootstrap_master]
  count = length(var.unmanaged_k8s.masters_ips)

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no ubuntu@${var.unmanaged_k8s.masters_ips[count.index]}:/home/ubuntu/join-command join-command-${var.unmanaged_k8s.masters_ips[count.index]}"
  }
}

data "template_file" "K8s_sanity_check" {
  count = length(var.unmanaged_k8s.clusters_nodes)

  template = file("templates/K8s_check.sh.template")
  vars = {
    nodes = var.unmanaged_k8s.clusters_nodes[count.index]
  }
}

resource "null_resource" "K8s_sanity_check" {
  depends_on = [null_resource.join_cluster]
  count = length(var.unmanaged_k8s.masters_ips)

  connection {
    host = var.unmanaged_k8s.masters_ips[count.index]
    type = "ssh"
    agent = false
    user = var.k8s.username
    private_key = file("/home/ubuntu/.ssh/id_rsa")
  }

  provisioner "file" {
    content = data.template_file.K8s_sanity_check[count.index].rendered
    destination = "K8s_sanity_check.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash K8s_sanity_check.sh",
    ]
  }
}

data "template_file" "values_ako_wo_nsx" {
  count = var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx" ? length(var.unmanaged_k8s.masters_ips) : 0
  template = file("templates/values.yml.1.10.1.template")
  vars = {
    disableStaticRouteSync = var.unmanaged_k8s.masters_ako_disableStaticRouteSync[count.index]
    clusterName  = var.unmanaged_k8s.masters_cluster_name[count.index]
    cniPlugin    = var.unmanaged_k8s.masters_cni[count.index]
    subnetIP     = split("/", var.vsphere_underlay.networks.alb.vip.cidr)[0]
    subnetPrefix = split("/", var.vsphere_underlay.networks.alb.vip.cidr)[1]
    networkName  = var.unmanaged_k8s.masters_vip_networks[count.index]
    serviceType  = var.unmanaged_k8s.masters_ako_serviceType[count.index]
    shardVSSize  = var.k8s.ako_shardVSSize
    loglevel     = var.k8s.ako_loglevel
    serviceEngineGroupName = var.unmanaged_k8s.masters_cluster_name[count.index]
    controllerVersion = var.avi.version
    cloudName    = var.avi.config.cloud.name
    controllerHost = var.vsphere_underlay.networks.vsphere.management.avi_nested_ip
    password = var.avi_password
  }
}

data "template_file" "values_ako_nsx" {
  count = var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd" ? length(var.unmanaged_k8s.masters_ips) : 0
  template = file("templates/values.yml.1.10.1.template")
  vars = {
    disableStaticRouteSync = var.unmanaged_k8s.masters_ako_disableStaticRouteSync[count.index]
    clusterName  = var.unmanaged_k8s.masters_cluster_name[count.index]
    cniPlugin    = var.unmanaged_k8s.masters_cni[count.index]
    subnetIP     = split("/", var.avi.config.cloud.networks_data[0].avi_ipam_vip.cidr)[0]
    subnetPrefix = split("/", var.avi.config.cloud.networks_data[0].avi_ipam_vip.cidr)[1]
    networkName  = var.unmanaged_k8s.masters_vip_networks[count.index]
    serviceType  = var.unmanaged_k8s.masters_ako_serviceType[count.index]
    shardVSSize  = var.k8s.ako_shardVSSize
    loglevel     = var.k8s.ako_loglevel
    serviceEngineGroupName = var.unmanaged_k8s.masters_cluster_name[count.index]
    controllerVersion = var.avi.version
    cloudName    = var.avi.config.cloud.name
    controllerHost = var.vsphere_underlay.networks.vsphere.management.avi_nested_ip
    password = var.avi_password
  }
}



data "template_file" "kube_config_script" {
  template = file("templates/kubeconfig.sh.template")
  vars = {
    cluster = length(var.unmanaged_k8s.masters_ips)
  }
}

resource "null_resource" "copy_k8s_config_file_to_external_gw" {
  depends_on = [null_resource.K8s_sanity_check]
  count = length(var.unmanaged_k8s.masters_ips)

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no ubuntu@${var.unmanaged_k8s.masters_ips[count.index]}:/home/ubuntu/.kube/config /home/ubuntu/.kube/config-${count.index + 1}"
  }

}

resource "null_resource" "copying_kube_config_locally" {
  depends_on = [null_resource.copy_k8s_config_file_to_external_gw]

  provisioner "local-exec" {
    command = "cat > kubeconfig.sh <<'EOF'\n${data.template_file.kube_config_script.rendered}\nEOF"
  }
}

resource "null_resource" "generating_kube_config_locally" {
  depends_on = [null_resource.copying_kube_config_locally]

  provisioner "local-exec" {
    command = "chmod u+x kubeconfig.sh ; /bin/bash kubeconfig.sh"
  }
}

resource "null_resource" "ako_config_locally_wo_nsx" {
  depends_on = [null_resource.generating_kube_config_locally]
  count = var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx" ? length(var.unmanaged_k8s.masters_cluster_name) : 0

  provisioner "local-exec" {
    command = "cat > /home/ubuntu/unmanaged_k8s.clusters/ako-values-${var.unmanaged_k8s.masters_cluster_name[count.index]}.yml <<EOL\n${data.template_file.values_ako_wo_nsx[count.index].rendered}\nEOL"
  }
}

resource "null_resource" "ako_config_locally_nsx" {
  depends_on = [null_resource.generating_kube_config_locally]
  count = var.deployment == "vsphere_nsx_alb" || var.deployment == "vsphere_nsx_tanzu_alb" || var.deployment == "vsphere_nsx_alb_vcd" ? length(var.unmanaged_k8s.masters_cluster_name) : 0

  provisioner "local-exec" {
    command = "cat > /home/ubuntu/unmanaged_k8s.clusters/ako-values-${var.unmanaged_k8s.masters_cluster_name[count.index]}.yml <<EOL\n${data.template_file.values_ako_nsx[count.index].rendered}\nEOL"
  }
}

resource "null_resource" "set_initial_state_ako_prerequisites" {
  count = 1
  depends_on = [null_resource.ako_config_locally_wo_nsx, null_resource.ako_config_locally_nsx]
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "echo \"0\" > masters.txt"
  }
}

resource "null_resource" "ako_prerequisites" {
  depends_on = [null_resource.set_initial_state_ako_prerequisites]
  count = length(var.unmanaged_k8s.masters_ips)

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "while [[ $(cat masters.txt) != \"${count.index}\" ]]; do echo \"${count.index} is waiting...\";sleep 5;done"
  }

  provisioner "local-exec" {
    command = "kubectl config use-context context${count.index + 1}; kubectl create ns avi-system ; kubectl create secret docker-registry docker --docker-server=docker.io --docker-username=${var.docker_registry_username} --docker-password=${var.docker_registry_password} --docker-email=${var.docker_registry_email}; kubectl patch serviceaccount default -p \"{\\\"imagePullSecrets\\\": [{\\\"name\\\": \\\"docker\\\"}]}\""
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "echo \"${count.index+1}\" > masters.txt"
  }

}