#!/bin/bash
jsonFile="/root/nested_vsphere.json"
cd /nestedVsphere8/03_nested_vsphere
terraform init
terraform destroy -auto-approve -var-file=$jsonFile
rm -fr terraform.tfstate .terraform.lock.hcl .terraform