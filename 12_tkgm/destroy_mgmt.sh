#!/bin/bash
#
jsonFile="/root/tkgm.json"
#
ssh -o StrictHostKeyChecking=no -t ubuntu@$(jq -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile) 'tanzu management-cluster delete '$(jq -r .tkg.clusters.management.name $jsonFile)''
/bin/bash govc_mgmt_destroy.sh
