#!/bin/bash
jsonFile="/root/unmanaged_k8s_clusters.json"
ssh -o StrictHostKeyChecking=no -t ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile) 'cd tf_remote_k8s ; terraform destroy -auto-approve -var-file=/home/ubuntu/unmanaged_k8s_clusters.json -var-file=/home/ubuntu/.environment_variables.json ; cd .. ; rm -fr tf_remote_k8s'
cd /nestedVsphere8/09_unmanaged_k8s_clusters
terraform init
terraform destroy -auto-approve -var-file=$jsonFile
rm -fr terraform.tfstate .terraform.lock.hcl .terraform
