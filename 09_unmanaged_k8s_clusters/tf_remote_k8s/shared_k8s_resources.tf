resource "vsphere_folder" "k8s" {
  count = length(var.unmanaged_k8s_masters_cluster_name)
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



