#!/bin/bash
#
jsonFile="/root/app.json"
#
# Apps VM deletion
#
ssh -o StrictHostKeyChecking=no -t ubuntu@$(jq  -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile) 'cd tf_remote_app ; terraform destroy -auto-approve -var-file=/home/ubuntu/app.json -var-file=/home/ubuntu/.environment_variables.json'
#
# Clean up of local terraform state
#
cd /nestedVsphere8/08_app
terraform init
terraform destroy -auto-approve -var-file=$jsonFile
rm -fr terraform.tfstate .terraform.lock.hcl .terraform
rm -f /root/08_app