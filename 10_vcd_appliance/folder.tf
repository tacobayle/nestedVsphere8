resource "vsphere_folder" "vcd" {
  path          = "vcd"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc_nested.id
}