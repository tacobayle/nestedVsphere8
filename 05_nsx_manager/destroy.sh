#!/bin/bash
jsonFile="/root/nsx.json"
cd /nestedVsphere8/05_nsx_manager
terraform init
terraform destroy -auto-approve -var-file=$jsonFile
rm -fr terraform.tfstate .terraform.lock.hcl .terraform