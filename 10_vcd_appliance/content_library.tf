resource "vsphere_content_library" "nested_library_vcd" {
  name            = "vcd"
  storage_backing = [data.vsphere_datastore.datastore_nested.id]
  description     = "vcd"
}

resource "vsphere_content_library_item" "nested_library_vcd_item" {
  name        = "vcd.ova"
  description = "vcd.ova"
  library_id  = vsphere_content_library.nested_library_vcd.id
  file_url = "/root/${basename(var.vcd_ova_path)}"
}