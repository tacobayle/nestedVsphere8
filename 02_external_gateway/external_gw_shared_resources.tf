resource "vsphere_content_library" "library_external_gw" {
  count = 1
  name            = "cl_tf_external_gw-${var.date_index}"
  storage_backing = [data.vsphere_datastore.datastore.id]
}

resource "vsphere_content_library_item" "file_external_gw" {
  count = 1
  name        = basename(var.ubuntu_ova_path)
  library_id  = vsphere_content_library.library_external_gw[0].id
  file_url = var.ubuntu_ova_path
}



resource "null_resource" "clear_ssh_key_external_gw_locally" {
  provisioner "local-exec" {
    command = "ssh-keygen -f \"/home/ubuntu/.ssh/known_hosts\" -R \"${var.vsphere_underlay.networks.vsphere.management.external_gw_ip}\" || true"
  }
}



data "template_file" "external_gw_userdata" {
  count = 1
  template = file("${path.module}/userdata/external_gw.userdata")
  vars = {
    pubkey        = file("/root/.ssh/id_rsa.pub")
    username = "ubuntu"
    ipCidr  = "${var.vsphere_underlay.networks.vsphere.management.external_gw_ip}/${var.vsphere_underlay.networks.vsphere.management.prefix}"
    ip = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    defaultGw = var.vsphere_underlay.networks.vsphere.management.gateway
    password      = var.ubuntu_password
    hostname = "external-gw-${var.date_index}"
    ip_vcenter = var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip
    vcenter_name = var.vsphere_nested.vcsa_name
    dns_domain = var.external_gw.bind.domain
    //    ip_data_cidr  = "${var.vsphere_underlay.networks.vsphere.management.external_gw_ip}/${var.vsphere_underlay.networks.vsphere.management.prefix}"
    dns      = join(", ", var.external_gw.bind.forwarders)
    netplanFile = "/etc/netplan/50-cloud-init.yaml"
    privateKey = "/root/.ssh/id_rsa"
    yaml_directory = var.yaml_directory
    ansible_version = var.ansible_version
    avi_sdk_version = var.avi_sdk_version
    forwarders = join("; ", var.external_gw.bind.forwarders)
    domain = var.external_gw.bind.domain
    reverse = var.external_gw.bind.reverse
    keyName = "myKeyName"
    secret = base64encode(var.bind_password)
    ntp = var.external_gw.ntp
    lastOctet = split(".", var.vsphere_underlay.networks.vsphere.management.external_gw_ip)[3]
    vcsa_nested_ip = var.vsphere_underlay.networks.vsphere.management.vcsa_nested_ip
    vcenter_name = var.vsphere_nested.vcsa_name
    vcd_ip = var.vcd_ip
    nfs_path = var.external_gw.nfs_path
    K8s_version = var.default_kubectl_version
    vault_secret_file_path = var.vault.secret_file_path
    vault_pki_name = var.vault.pki.name
    vault_pki_max_lease_ttl = var.vault.pki.max_lease_ttl
    vault_pki_cert_common_name = var.vault.pki.cert.common_name
    vault_pki_cert_issuer_name = var.vault.pki.cert.issuer_name
    vault_pki_cert_ttl = var.vault.pki.cert.ttl
    vault_pki_cert_path = var.vault.pki.cert.path
    vault_pki_issuers_file = var.vault.pki.issuers_file
    vault_pki_role_name = var.vault.pki.role.name
    vault_pki_intermediate_name = var.vault.pki_intermediate.name
    vault_pki_intermediate_max_lease_ttl = var.vault.pki_intermediate.max_lease_ttl
    vault_pki_intermediate_cert_common_name = var.vault.pki_intermediate.cert.common_name
    vault_pki_intermediate_cert_issuer_name = var.vault.pki_intermediate.cert.issuer_name
    vault_pki_intermediate_cert_path = var.vault.pki_intermediate.cert.path
    vault_pki_intermediate_cert_path_signed = var.vault.pki_intermediate.cert.path_signed
    vault_pki_intermediate_role_name = var.vault.pki_intermediate.role.name
    vault_pki_intermediate_role_allow_subdomains = var.vault.pki_intermediate.role.allow_subdomains
    vault_pki_intermediate_role_max_ttl = var.vault.pki_intermediate.role.max_ttl
    avi_domain_prefix = var.avi_domain_prefix
    avi_dns_ip = var.avi_dns_ip
  }
}

resource "null_resource" "yaml_replace_avi_domain" {
  depends_on = [vsphere_virtual_machine.external_gw]

  connection {
    host        = var.vsphere_underlay.networks.vsphere.management.external_gw_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file("/root/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = "/root/external_gw.json"
    destination = "/home/ubuntu/external_gw.json"
  }

  provisioner "file" {
    source      = "/nestedVsphere8/02_external_gateway/bash/yaml_replace_avi_domain.sh"
    destination = "/home/ubuntu/${var.yaml_directory}/yaml_replace_avi_domain.sh"
  }

  provisioner "remote-exec" {
    inline      = [
      "/bin/bash /home/ubuntu/${var.yaml_directory}/yaml_replace_avi_domain.sh"
    ]
  }

}

resource "null_resource" "configure_lbaas" {
  depends_on = [null_resource.yaml_replace_avi_domain]

  provisioner "local-exec" {
    command = "/bin/bash bash/configure_lbaas.sh"
  }

}

resource "null_resource" "configure_traffic_gen" {
  depends_on = [null_resource.configure_lbaas]

  provisioner "local-exec" {
    command = "/bin/bash bash/configure_traffic_gen.sh"
  }

}