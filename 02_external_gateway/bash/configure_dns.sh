#!/bin/bash
if [[ ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_tanzu_alb" ]]; then
  jsonFile="/root/external_gw.json"
  forwarders=$(jq -c -r '.external_gw.bind.forwarders | join(", ")' ${jsonFile})
  external_gw_ip=$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip ${jsonFile})
  ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip} "sudo mv /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.old"
  ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip}  "cat /etc/netplan/50-cloud-init.yaml.old | sed -e  \"s/${forwarders}/127.0.0.1/\" | sudo tee /etc/netplan/50-cloud-init.yaml"
  ssh -o StrictHostKeyChecking=no -t ubuntu@${external_gw_ip}  "sudo netplan apply"
fi