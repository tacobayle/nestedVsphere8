resource "vsphere_content_library" "nested_library_se" {
  name            = var.nsx_alb_se_cl
  storage_backing = [data.vsphere_datastore.datastore_nested.id]
}

resource "null_resource" "wait_https_controller" {

  provisioner "local-exec" {
    command = "until $(curl --output /dev/null --silent --head -k https://${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip}); do echo 'Waiting for Avi Controllers to be ready'; sleep 60 ; done"
  }
}

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

data "template_file" "values_nsx" {
  count = var.deployment == "vsphere_tanzu_nsx_alb" ? 1 : 0
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
    content_library = vsphere_content_library.nested_library_se.name
    service_engine_groups = jsonencode(var.avi.config.cloud.service_engine_groups)
    pools = jsonencode(var.avi.config.cloud.pools)
    virtual_services = jsonencode(var.avi.config.cloud.virtual_services)
    external_gw_ip = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
  }
}

data "template_file" "values_vcenter" {
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0
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
    vsphere_server = var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip
    domain = var.external_gw.bind.domain
    ipam = var.avi.config.cloud.ipam
    cloud_name = var.avi.config.cloud.name
    dc = var.vsphere_nested.datacenter
    content_library_id = vsphere_content_library.nested_library_se.id
    content_library_name = vsphere_content_library.nested_library_se.name
    dhcp_enabled = false
    networks = var.avi.config.cloud.networks
    pools = var.avi.config.cloud.pools
    virtual_services = var.avi.config.cloud.virtual_services
  }
}

resource "null_resource" "alb_ansible_config_values_nsx" {
  count = var.deployment == "vsphere_tanzu_nsx_alb" ? 1 : 0

  provisioner "local-exec" {
    command = "cat > values.yml <<EOL\n${data.template_file.values_nsx[0].rendered}\nEOL"
  }
}

resource "null_resource" "alb_ansible_config_values_vcenter" {
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0

  provisioner "local-exec" {
    command = "cat > values.yml <<EOL\n${data.template_file.values_vcenter[0].rendered}\nEOL"
  }
}

resource "null_resource" "alb_ansible_config_nsx" {
  count = var.deployment == "vsphere_tanzu_nsx_alb" ? 1 : 0
  depends_on = [null_resource.ansible_hosts_avi_controllers, null_resource.alb_ansible_config_values_nsx, null_resource.alb_ansible_config_values_vcenter, null_resource.wait_https_controller]
  provisioner "local-exec" {
    command = "git clone ${var.avi.config.avi_config_repo} --branch ${var.avi.config.avi_config_tag} ; cd ${split("/", var.avi.config.avi_config_repo)[4]} ; ansible-playbook -i ../hosts_avi ${var.avi.config.playbook} --extra-vars @../values.yml"
  }
}

resource "null_resource" "alb_ansible_config_vcenter" {
  count = var.deployment == "vsphere_tanzu_alb_wo_nsx" ? 1 : 0
  depends_on = [null_resource.ansible_hosts_avi_controllers, null_resource.alb_ansible_config_values_nsx, null_resource.alb_ansible_config_values_vcenter, null_resource.wait_https_controller]
  provisioner "local-exec" {
    command = "git clone ${var.avi.config.avi_config_repo} --branch ${var.avi.config.avi_config_tag} ; cd ${split("/", var.avi.config.avi_config_repo)[4]} ; ansible-playbook -i ../hosts_avi ${var.avi.config.playbook} --extra-vars @../values.yml"
  }
}


data "template_file" "traffic_gen" {
  template = file("templates/traffic_gen.sh.template")
  vars = {
    controllerPrivateIp = jsonencode(var.vsphere_underlay.networks.vsphere.management.avi_nested_ip)
    avi_password = jsonencode(var.avi_password)
    avi_username = "admin"
  }
}

resource "null_resource" "transfer_traffic_gen" {
  depends_on = [null_resource.alb_ansible_config_nsx, null_resource.alb_ansible_config_vcenter]

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    content = data.template_file.traffic_gen.rendered
    destination = "/home/ubuntu/traffic_gen.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod u+x /home/ubuntu/traffic_gen.sh",
      "(crontab -l 2>/dev/null; echo \"* * * * * /home/ubuntu/traffic_gen.sh\") | crontab -"
    ]
  }

}

#
# Need to update Avi UI/API cert.
#

resource "null_resource" "dump_alb_cert_locally" {
  depends_on = [null_resource.alb_ansible_config_nsx]
  provisioner "local-exec" {
    command = "echo -n | openssl s_client -connect ${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip}:443 -servername ${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip} | openssl x509 | tee /root/${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip}.cert"
  }
}