#!/bin/bash
jsonFile="/root/avi.json"
cd /nestedVsphere8/07_nsx_alb
terraform init
terraform destroy -auto-approve -var-file=$jsonFile
rm -fr terraform.tfstate .terraform.lock.hcl .terraform
rm -f /root/07_nsx_alb