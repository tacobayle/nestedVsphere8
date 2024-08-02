data "template_file" "values" {
  count = var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx" || var.deployment == "vsphere_nsx_alb_telco" ? 1 : 0
  template = file("templates/values_vcenter.yml.template")
  vars = {
    controllerPrivateIp = jsonencode(var.vsphere_underlay.networks.vsphere.management.avi_nested_ip)
    ntp = jsonencode(var.vsphere_underlay.networks.vsphere.management.external_gw_ip)
    dns = jsonencode(var.vsphere_underlay.networks.vsphere.management.external_gw_ip)
    avi_password = jsonencode(var.avi_password)
    avi_old_password =  jsonencode(var.avi_old_password)
    avi_version = var.avi.version
    avi_username = "admin"
    vsphere_username = "administrator@${var.vsphere_nested.sso.domain_name}"
    vsphere_password = var.vsphere_nested_password
    tenants = jsonencode(var.avi.config.tenants)
    users = jsonencode(var.avi.config.users)
    vsphere_server = var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip
    external_gw_ip = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    sslkeyandcertificate = jsonencode(var.avi.config.sslkeyandcertificate)
    sslkeyandcertificate_ref = var.avi.config.portal_configuration.sslkeyandcertificate_ref
    alertscriptconfig = jsonencode(var.avi.config.alertscriptconfig)
    certificatemanagementprofile = jsonencode(var.avi.config.certificatemanagementprofile)
    import_sslkeyandcertificate_ca = jsonencode(var.avi.config.import_sslkeyandcertificate_ca)
    actiongroupconfig = jsonencode(var.avi.config.actiongroupconfig)
    alertconfig = jsonencode(var.avi.config.alertconfig)
    external_gw_se_ip = var.vsphere_underlay.networks.alb.se.external_gw_ip
    domain = jsonencode(var.avi.config.domain)
    ipam = jsonencode(var.avi.config.cloud.ipam)
    cloud_name = var.avi.config.cloud.name
    additional_subnets = jsonencode(var.avi.config.cloud.additional_subnets)
    contexts = jsonencode(var.avi.config.cloud.contexts)
    dc = var.vsphere_nested.datacenter
    content_library_id = vsphere_content_library.nested_library_se.id
    content_library_name = vsphere_content_library.nested_library_se.name
    dhcp_enabled = false
    networks = jsonencode(var.avi.config.cloud.networks)
    service_engine_groups = jsonencode(var.avi.config.cloud.service_engine_groups)
    pools = jsonencode(var.avi.config.cloud.pools)
    virtual_services = jsonencode(var.avi.config.cloud.virtual_services)
  }
}


resource "null_resource" "alb_ansible_config_values" {
  count = var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx" || var.deployment == "vsphere_nsx_alb_telco" ? 1 : 0

  provisioner "local-exec" {
    command = "cat > values.yml <<EOL\n${data.template_file.values[0].rendered}\nEOL"
  }
}


resource "null_resource" "alb_ansible_config" {
  count = var.deployment == "vsphere_alb_wo_nsx" || var.deployment == "vsphere_tanzu_alb_wo_nsx" || var.deployment == "vsphere_nsx_alb_telco" ? 1 : 0
  depends_on = [null_resource.ansible_hosts_avi_controllers, null_resource.alb_ansible_config_values, null_resource.wait_https_controller]
  provisioner "local-exec" {
    command = "git clone ${var.avi.config.avi_config_repo} --branch ${var.avi.config.avi_config_tag} ; cd ${split("/", var.avi.config.avi_config_repo)[4]} ; ansible-playbook -i ../hosts_avi ${var.avi.config.playbook} --extra-vars @../values.yml"
  }
}