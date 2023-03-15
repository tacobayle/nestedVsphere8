resource "null_resource" "ansible_hosts_avi_header_1" {
  provisioner "local-exec" {
    command = "echo '---' | tee hosts_avi; echo 'all:' | tee -a hosts_avi ; echo '  children:' | tee -a hosts_avi; echo '    controller:' | tee -a hosts_avi; echo '      hosts:' | tee -a hosts_avi"
  }
}

resource "null_resource" "ansible_hosts_avi_controllers" {
  depends_on = [null_resource.ansible_hosts_avi_header_1]
  provisioner "local-exec" {
    command = "echo '        ${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip}:' | tee -a hosts_avi "
  }
}

data "template_file" "values" {
  template = file("templates/values_nsx.yml.template")
  vars = {
    avi_version = var.avi.version
    controllerPrivateIp = jsonencode(var.vsphere_underlay.networks.vsphere.management.avi_nested_ip)
    avi_old_password =  jsonencode(var.avi_old_password)
    avi_password = jsonencode(var.avi_password)
    avi_username = "admin"
    ntp = jsonencode(var.vsphere_underlay.networks.vsphere.management.external_gw_ip)
    dns = jsonencode(var.vsphere_underlay.networks.vsphere.management.external_gw_ip)
    nsx_password = var.nsx_password
    nsx_server = var.vsphere_underlay.networks.vsphere.management.nsx_nested_ip
    domain = var.external_gw.bind.domain
    cloud_name = var.avi.config.cloud.name
    cloud_obj_name_prefix = var.avi.config.cloud.obj_name_prefix
    transport_zone_name = var.transport_zone
    network_management = jsonencode(var.avi.config.cloud.network_management)
    networks_data = jsonencode(var.avi.config.cloud.networks_data)
    sso_domain = var.vsphere_nested.sso.domain_name
    vcenter_password = var.vsphere_nested_password
    vcenter_ip = var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip
    content_library = var.nsx_alb_se_cl
    service_engine_groups = jsonencode(var.avi.config.cloud.service_engine_groups)
    pools = jsonencode(var.avi.config.cloud.pools)
    virtual_services = jsonencode(var.avi.config.cloud.virtual_services)
  }
}

resource "null_resource" "alb_ansible_config_values" {

  provisioner "local-exec" {
    command = "cat > values.yml <<EOL\n${data.template_file.values.rendered}\nEOL"
  }
}


resource "null_resource" "alb_ansible_config" {
  depends_on = [null_resource.ansible_hosts_avi_controllers, null_resource.alb_ansible_config_values]
  provisioner "local-exec" {
    command = "git clone ${var.avi.config.avi_config_repo} --branch ${var.avi.config.avi_config_tag} ; cd ${split("/", var.avi.config.avi_config_repo)[4]} ; ansible-playbook -i ../hosts_avi ${var.avi.config.playbook_nsx_env_nsx_cloud} --extra-vars @../values.yml"
  }
}