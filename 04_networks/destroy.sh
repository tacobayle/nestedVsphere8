#!/bin/bash
jsonFile="/root/networks.json"
cd /nestedVsphere8/04_networks
terraform init
terraform destroy -auto-approve -var-file=$jsonFile
rm -fr terraform.tfstate .terraform.lock.hcl .terraform