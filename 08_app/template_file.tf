data "template_file" "environment_variables" {
  template = file("templates/environment_variables.json.template")
  vars = {
    vsphere_nested_password = var.vsphere_nested_password
    ubuntu_password = var.ubuntu_password
    docker_registry_username = var.docker_registry_username
    docker_registry_password = var.docker_registry_password
  }
}