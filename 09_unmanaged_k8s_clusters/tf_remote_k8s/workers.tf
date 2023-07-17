data "vsphere_folder" "k8s_workers_folders"{
  count = length(var.unmanaged_k8s_workers_cluster_name)
  depends_on = [vsphere_folder.k8s]
  path = "/${var.vsphere_nested.datacenter}/vm/${var.k8s.folder_basename}-${var.unmanaged_k8s_workers_cluster_name[count.index]}"
}


data "template_file" "k8s_workers_userdata" {
  count = length(var.unmanaged_k8s_workers_ips)
  template = file("${path.module}/userdata/k8s.userdata")
  vars = {
    username     = var.k8s.username
    hostname     = "${var.k8s.worker_basename}-${var.unmanaged_k8s_workers_cluster_name[count.index + 1]}"
    password      = var.ubuntu_password
    pubkey       = file("/home/ubuntu/.ssh/id_rsa.pub")
    netplan_file  = var.k8s.netplan_file
    prefix = split("/", var.unmanaged_k8s_workers_cidr[count.index])[1]
    ip = var.unmanaged_k8s_workers_ips[count.index]
    default_gw = var.unmanaged_k8s_workers_gw[count.index]
    dns = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
  }
}

resource "vsphere_virtual_machine" "workers" {
  count = length(var.unmanaged_k8s_workers_ips)
  name             = "${var.k8s.worker_basename}-${unmanaged_k8s_workers_count[count.index]}"
  datastore_id     = data.vsphere_datastore.datastore_nested.id
  resource_pool_id = data.vsphere_resource_pool.resource_pool_nested.id
  folder           = data.vsphere_folder.k8s_workers_folders[count.index].path

  network_interface {
    network_id = data.vsphere_network.k8s_workers_networks[count.index].id
  }

  num_cpus = var.k8s.worker_cpu
  memory = var.k8s.worker_memory
  guest_id = "ubuntu64Guest"
  wait_for_guest_net_timeout = 10

  disk {
    size             = var.k8s.worker_disk
    label            = "${var.k8s.worker_basename}-cluster-${count.index + 1}.lab_vmdk"
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
      hostname    = "${var.k8s.worker_basename}-${var.unmanaged_k8s_workers_cluster_name[count.index + 1]}"
      public-keys = file("/home/ubuntu/.ssh/id_rsa.pub")
      user-data   = base64encode(data.template_file.k8s_workers_userdata[count.index].rendered)
    }
  }

  connection {
    host        = var.unmanaged_k8s_workers_ips[count.index]
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

data "template_file" "k8s_bootstrap_workers" {
  template = file("${path.module}/templates/k8s_bootstrap_workers.template")
  count = length(var.unmanaged_k8s_workers_ips)
  vars = {
    net_plan_file = var.k8s.netplan_file
    K8s_version = var.unmanaged_k8s_workers_version[count.index]
    Docker_version = var.k8s.docker_version
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
    cni_name = var.unmanaged_k8s_workers_cni[count.index]
    cni_version = var.unmanaged_k8s_workers_cni_version[count.index]
  }
}

resource "null_resource" "k8s_bootstrap_workers" {
  count = length(var.unmanaged_k8s_workers_ips)
  depends_on = [vsphere_virtual_machine.workers]

  connection {
    host = vsphere_virtual_machine.workers[count.index].default_ip_address
    type = "ssh"
    agent = false
    user = "ubuntu"
    private_key = file("/home/ubuntu/.ssh/id_rsa")
  }

  provisioner "file" {
    content = data.template_file.k8s_bootstrap_workers[count.index].rendered
    destination = "k8s_bootstrap_workers.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo /bin/bash k8s_bootstrap_workers.sh"]
  }

}

resource "null_resource" "copy_join_command_to_workers" {
  count = length(var.unmanaged_k8s_workers_ips)
  depends_on = [null_resource.copy_join_command_to_tf, null_resource.k8s_bootstrap_workers]

  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${var.unmanaged_k8s_workers_ips[count.index]}\""
  }
}

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no join-command-${var.unmanaged_k8s_workers_associated_master_ips[count.index]} ubuntu@${vsphere_virtual_machine.workers[count.index].default_ip_address}:/home/ubuntu/join-command"
  }
}

resource "null_resource" "join_cluster" {
  depends_on = [null_resource.copy_join_command_to_workers]
  count = length(var.unmanaged_k8s_workers_ips)
  connection {
    host        = vsphere_virtual_machine.workers[count.index].default_ip_address
    type        = "ssh"
    agent       = false
    user = "ubuntu"
    private_key = file("/home/ubuntu/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline      = [
      "sudo /bin/bash /home/ubuntu/join-command-${var.unmanaged_k8s_workers_associated_master_ips[count.index]}"
    ]
  }
}