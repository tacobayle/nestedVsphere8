resource "null_resource" "retrieve_avi_cert" {
  depends_on = [null_resource.alb_ansible_config]
  provisioner "local-exec" {
    command = "rm -f /root/avi_cert.txt ; openssl s_client -connect ${var.vsphere_underlay.networks.vsphere.management.avi_nested_ip}:443 2>/dev/null </dev/null |  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | tee /root/avi_cert.txt > /dev/null "
  }
}