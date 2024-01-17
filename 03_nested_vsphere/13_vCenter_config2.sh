#!/bin/bash
#
jsonFile="/root/nested_vsphere.json"
#
api_host="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vsphere_nested_username=administrator
vcenter_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
vsphere_nested_password=$TF_VAR_vsphere_nested_password
#
source /nestedVsphere8/bash/govc/variables.sh
#
IFS=$'\n'
#
# Cleaning unused Standard vswitch config and VM port group
#
echo "++++++++++++++++++++++++++++++++"
echo "Cleaning unused Standard vswitch config"
IFS=$'\n'
load_govc_esxi
echo ""
echo "++++++++++++++++++++++++++++++++"
for ip in $(cat $jsonFile | jq -c -r .vsphere_underlay.networks.vsphere.management.esxi_ips[])
do
  export GOVC_URL=$ip
  echo "Deleting port group called VM Network for Host $ip"
  govc host.esxcli network vswitch standard portgroup remove -p "VM Network" -v "vSwitch0"
  echo "Deleting port group called Management Network for Host $ip"
  govc host.esxcli network vswitch standard portgroup remove -p "Management Network" -v "vSwitch0"
  echo "Deleting vswitch called vSwitch0 for Host $ip"
  govc host.esxcli network vswitch standard remove -v vSwitch0
  echo "Deleting vswitch called vSwitch1 for Host $ip"
  govc host.esxcli network vswitch standard remove -v vSwitch1
  echo "Deleting vswitch called vSwitch2 for Host $ip"
  govc host.esxcli network vswitch standard remove -v vSwitch2
done
#
# VSAN Configuration
#
for cluster in $(jq -r .vsphere_nested.cluster_list[] $jsonFile)
do
  load_govc_env_with_cluster "${cluster}"
  echo "Enabling VSAN configuration for cluster called ${cluster}"
  govc cluster.change -drs-enabled -ha-enabled -vsan-enabled -vsan-autoclaim "${cluster}"
done
# Adding host in VSAN config.
count=0
for ip in $(jq -r .vsphere_underlay.networks.vsphere.management.esxi_ips[] $jsonFile)
do
  load_govc_esxi
  if [[ $count -ne 0 ]] ; then
    export GOVC_URL=$ip
    echo "make sure vmk2 is tagged with service VSAN"
    govc host.esxcli network ip interface tag add -i vmk2 -t VSAN || true
    echo "Adding host $ip in VSAN configuration"
    govc host.esxcli vsan storage tag add -t capacityFlash -d "$(jq -r .capacity_disk $jsonFile)"
    govc host.esxcli vsan storage add --disks "$(jq -r .capacity_disk $jsonFile)" -s "$(jq -r .cache_disk $jsonFile)"
  fi
  count=$((count+1))
done
#
# Saving vSphere certificate
#
echo -n | openssl s_client -connect $api_host:443 -servername $api_host | openssl x509 | tee /root/$api_host.cert