#!/bin/bash
jsonFile="/root/avi.json"
cd /nestedVsphere8/10_nsx_alb_config
terraform init
terraform destroy -auto-approve -var-file=$jsonFile
rm -fr terraform.tfstate .terraform.lock.hcl .terraform
rm -fr ansibleAviConfig
rm -fr values.yml