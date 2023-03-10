resource "nsxt_vm_tags" "avi_app_tag" {
  instance_id = vsphere_virtual_machine.avi_app[0].id
  tag {
    tag   = var.app.nsxt_vm_tags
  }
}

resource "nsxt_policy_group" "backend" {
  display_name = var.app.nsxt_group_name

  criteria {
    condition {
      key = "Tag"
      member_type = "VirtualMachine"
      operator = "EQUALS"
      value = var.app.nsxt_vm_tags
    }
  }
}