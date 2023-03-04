resource "vsphere_content_library" "nested_library_nsx" {
  name            = "NSX Library"
  storage_backing = [data.vsphere_datastore.datastore_nested.id]
}

resource "vsphere_content_library_item" "nested_library_nsx_item" {
  name            = basename(var.nsx_ova_path)
  library_id      = vsphere_content_library.nested_library_nsx.id
  file_url        = var.nsx_ova_path
}