data "template_file" "k8s_masters_userdata" {
  count = length(var.unmanaged_k8s_masters_ips)
  template = file("${path.module}/userdata/k8s.userdata")
  vars = {
    username     = var.k8s.username
    hostname     = "${var.k8s.master_basename}-1"
    password      = var.ubuntu_password
    pubkey       = file("/home/ubuntu/.ssh/id_rsa.pub")
    netplan_file  = var.k8s.netplan_file
    prefix = split("/", var.unmanaged_k8s_masters_cidr[count.index])[1]
    ip = var.unmanaged_k8s_masters_ips[count.index]
    default_gw = var.unmanaged_k8s_masters_gw[count.index]
    dns = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
  }
}

resource "vsphere_virtual_machine" "masters" {
  count = length(var.unmanaged_k8s_masters_ips)
  name             = "${var.k8s.master_basename}-1"
  datastore_id     = data.vsphere_datastore.datastore_nested.id
  resource_pool_id = data.vsphere_resource_pool.resource_pool_nested.id
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
    host        = var.unmanaged_k8s_masters_ips[count.index]
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
  count = length(var.unmanaged_k8s_masters_ips)

  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/${var.k8s.username}/.ssh/known_hosts\" -R \"${var.unmanaged_k8s_masters_ips[count.index]}\""
  }
}

data "template_file" "k8s_bootstrap_master" {
  count = length(var.unmanaged_k8s_masters_ips)
  template = file("${path.module}/templates/k8s_bootstrap_master.template")
  vars = {
    docker_registry_username = var.docker_registry_username
    K8s_pod_cidr = var.k8s.pod_cidr
    K8s_version = var.unmanaged_k8s_masters_version[count.index]
    Docker_version = var.k8s.docker_version
    docker_registry_password = var.docker_registry_password
    cni_name = var.unmanaged_k8s_masters_cni[count.index]
    cni_version = var.unmanaged_k8s_masters_cni_version[count.index]
  }
}

resource "null_resource" "k8s_bootstrap_master" {
  depends_on = [null_resource.clear_ssh_keys_masters]
  count = length(var.unmanaged_k8s_masters_ips)


  connection {
    host        = var.unmanaged_k8s_masters_ips[count.index]
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
  count = length(var.unmanaged_k8s_masters_ips)

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no ubuntu@${vsphere_virtual_machine.masters[count.index].default_ip_address}:/home/ubuntu/join-command join-command-${var.unmanaged_k8s_masters_ips[count.index]}"
  }
}

data "template_file" "K8s_sanity_check" {
  count = length(var.unmanaged_k8s_clusters_nodes)

  template = file("templates/K8s_check.sh.template")
  vars = {
    nodes = var.unmanaged_k8s_clusters_nodes[count.index]
  }
}

resource "null_resource" "K8s_sanity_check" {
  depends_on = [null_resource.join_cluster]
  count = length(var.unmanaged_k8s_masters_ips)

  connection {
    host = vsphere_virtual_machine.masters[count.index].default_ip_address
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
