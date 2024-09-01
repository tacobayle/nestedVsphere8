resource "vsphere_folder" "k8s" {
  count         = length(var.unmanaged_k8s.masters_cluster_name)
  path          = "${var.k8s.folder_basename}-${var.unmanaged_k8s.masters_cluster_name[count.index]}"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}

data "vsphere_content_library" "nested_library_k8s_unmanaged" {
  name            = var.ubuntu_cl
  storage_backing = [data.vsphere_datastore.datastore_nested.id]
}

data "vsphere_content_library_item" "nested_library_k8s_unmanaged_item" {
  name        = var.ubuntu_ova
  type       = "vm-template"
  library_id  = data.vsphere_content_library.nested_library_k8s_unmanaged.id
}