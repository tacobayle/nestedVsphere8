resource "vsphere_folder" "k8s" {
  count = length(var.unmanaged_k8s_masters_ips)
  path          = "${var.k8s.folder_basename}-${var.unmanaged_k8s_masters_cluster_name[count.index]}"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

resource "vsphere_content_library" "nested_library_k8s_unmanaged" {
  name            = "k8s_unmanaged"
  storage_backing = [data.vsphere_datastore.datastore_nested.id]
}

resource "vsphere_content_library_item" "nested_library_k8s_unmanaged_item" {
  name        = "ubuntu.ova"
  library_id  = vsphere_content_library.nested_library_k8s_unmanaged.id
  file_url = "/home/ubuntu/${basename(var.ubuntu_ova_path)}"
}

data "template_file" "k8s_userdata" {
  count = length(var.unmanaged_k8s_masters_ips)
  template = file("${path.module}/userdata/k8s.userdata")
  vars = {
    username     = var.k8s.username
    hostname     = "${var.k8s.master_basename}-cluster-${count.index + 1}"
    password      = var.ubuntu_password
    pubkey       = file("/home/ubuntu/.ssh/id_rsa.pub")
    netplan_file  = var.k8s.netplan_file
    prefix = split("/", var.unmanaged_k8s_masters_cidr[count.index])[1]
    ip = var.unmanaged_k8s_masters_ips[count.index]
    default_gw = var.unmanaged_k8s_masters_gw[count.index]
    dns = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
  }
}

data "template_file" "k8s_bootstrap_master" {
  count = length(var.unmanaged_k8s_masters_ips)
  template = file("${path.module}/templates/k8s_bootstrap_master.template")
  vars = {
    net_plan_file = var.k8s.netplan_file
    docker_registry_username = var.docker_registry_username
    K8s_pod_cidr = var.k8s.pod_cidr
    K8s_version = var.unmanaged_k8s_masters_version[count.index]
    Docker_version = var.k8s.docker_version
    docker_registry_password = var.docker_registry_password
    cni_name = var.unmanaged_k8s_masters_cni_name[count.index]
    cni_version = var.unmanaged_k8s_masters_cni_version[count.index]
    ako_service_type = local.ako_service_type
    dhcp = var.vcenter_network_mgmt_dhcp
  }
}

resource "vsphere_virtual_machine" "masters" {
  count = length(var.unmanaged_k8s_masters_ips)
  name             = "${var.k8s.master_basename}-cluster-${count.index + 1}"
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
    label            = "${var.k8s.master_basename}-cluster-${count.index + 1}.lab_vmdk"
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
      hostname    = "${var.k8s.master_basename}-cluster-${count.index + 1}"
      public-keys = file("/home/ubuntu/.ssh/id_rsa.pub")
      user-data   = base64encode(data.template_file.k8s_userdata[count.index].rendered)
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

data "template_file" "k8s_bootstrap_workers" {
  template = file("${path.module}/templates/k8s_bootstrap_workers.template")
  count = 2
  vars = {
    net_plan_file = var.master.net_plan_file
    K8s_version = var.K8s_version
    Docker_version = var.k8s.docker_version
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
    cni_name = var.unmanaged_k8s_workers_cni_name[count.index]
    cni_version = var.unmanaged_k8s_workers_cni_version[count.index]
    ako_service_type = local.ako_service_type
    dhcp = var.vcenter_network_mgmt_dhcp
    ip_k8s = split(",", replace(var.vcenter_network_k8s_ip4_addresses, " ", ""))[1 + count.index]
  }
}