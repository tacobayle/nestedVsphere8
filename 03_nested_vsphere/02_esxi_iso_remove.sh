#!/bin/bash
#
jsonFile="/root/nested_vsphere.json"
#
iso_location=$(jq -r .iso_location $jsonFile)
count=$(jq -c -r '.vsphere_underlay.networks.vsphere.management.esxi_ips | length' $jsonFile)
#
for esx in $(seq 0 $(expr $count - 1))
do
  echo ""
  echo "++++++++++++++++++++++++++++++++"
  echo "removing ESXi Custom ISOs"
  rm -f $iso_location$esx.iso
done
