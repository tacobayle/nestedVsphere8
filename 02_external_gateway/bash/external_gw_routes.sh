#!/bin/bash
jsonFile="/root/external_gw.json"
external_gw_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
#
#
#
scp -o StrictHostKeyChecking=no /root/external_gw_routes.yml ubuntu${external_gw_ip}:/home/ubuntu/routes/external_gw_routes.yml
ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "cat /home/ubuntu/routes/external_gw_routes.yml | sudo tee -a /etc/netplan/50-cloud-init.yaml > /dev/null"