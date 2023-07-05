#!/bin/bash
#
jsonFile="/root/nested_vsphere.json"
#
export GOVC_USERNAME=root
export GOVC_PASSWORD=$(echo $TF_VAR_nested_esxi_root_password)
export GOVC_INSECURE=true
unset GOVC_DATACENTER
unset GOVC_CLUSTER
unset GOVC_URL
#
IFS=$'\n'
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Configure ESXi disks as SSD"
for ip in $(jq -c -r .vsphere_underlay.networks.vsphere.management.esxi_ips[] $jsonFile)
do
  export GOVC_URL=$ip
  echo "+++++++++++++++++++"
  echo "Mark all disks as SSD for ESXi host $ip"
  EsxiMarkDiskAsSsd=$(govc host.storage.info -rescan | grep /vmfs/devices/disks | awk '{print $1}' | sort)
  for u in ${EsxiMarkDiskAsSsd[@]} ; do govc host.storage.mark -ssd $u ; done
done
