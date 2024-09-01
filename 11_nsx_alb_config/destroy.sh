#!/bin/bash
echo "Destroying NSX ALB config (11_nsx_alb_config) and ALB controller (07_nsx_alb_config)"
jsonFile="/root/avi.json"
cd /nestedVsphere8/11_nsx_alb_config
terraform init
terraform destroy -auto-approve -var-file=$jsonFile
rm -fr terraform.tfstate .terraform.lock.hcl .terraform
rm -fr ansibleAviConfig
rm -fr values.yml
rm -f /root/11_nsx_alb_config
/bin/bash /nestedVsphere8/07_nsx_alb/destroy.sh
rm -f /root/07_nsx_alb