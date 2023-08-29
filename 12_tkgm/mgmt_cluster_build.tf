resource "null_resource" "govc_bash_script_mgmt" {

  provisioner "local-exec" {
    command = "cat > govc_mgmt.sh <<EOL\n${data.template_file.govc_bash_script_mgmt.rendered}\nEOL"
  }

  provisioner "local-exec" {
    command = "/bin/bash govc_mgmt.sh"
  }

}