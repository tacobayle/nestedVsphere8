#!/bin/bash
echo "Destroying NSX config (06_nsx_config) , NSX manager (05_nsx_manager), Networks (04_networks) and nested vSphere (03_nested_vsphere)"
jsonFile="/root/nsx.json"
cd /nestedVsphere8/06_nsx_config
terraform init
terraform destroy -auto-approve -var-file=$jsonFile
rm -fr terraform.tfstate .terraform.lock.hcl .terraform
rm -f /root/06_nsx_config
/bin/bash /nestedVsphere8/05_nsx_manager/destroy.sh
/bin/bash /nestedVsphere8/04_networks/destroy.sh
/bin/bash /nestedVsphere8/03_nested_vsphere/destroy.sh
