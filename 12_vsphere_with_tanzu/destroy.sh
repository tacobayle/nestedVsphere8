#!/bin/bash
#
source /nestedVsphere8/bash/vcenter_api.sh
#
jsonFile="/root/vsphere_with_tanzu.json"
#
IFS=$'\n'
#
api_host="$(jq -r .vsphere_nested.vcsa_name $jsonFile).$(jq -r .external_gw.bind.domain $jsonFile)"
vsphere_nested_username=administrator
vcenter_domain=$(jq -r .vsphere_nested.sso.domain_name $jsonFile)
vsphere_nested_password=$TF_VAR_vsphere_nested_password
#
token=$(/bin/bash /nestedVsphere8/bash/create_vcenter_api_session.sh "$vsphere_nested_username" "$vcenter_domain" "$vsphere_nested_password" "$api_host")
#
# TKC Clusters deletion
#
ssh-keygen -f "/root/.ssh/known_hosts" -R $(jq  -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
ssh -o StrictHostKeyChecking=no -t ubuntu@$(jq  -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile) '/bin/bash /home/ubuntu/tkc/tkc_destroy.sh'
#
# Namespace deletion
#
for ns in $(jq -c -r .tanzu.namespaces[] $jsonFile); do
  ns_name=$(echo $ns | jq -r .name)
  vcenter_api 6 10 "DELETE" $token "" $api_host "api/vcenter/namespaces/instances/${ns_name}"
done
#
# Supervisor cluster Deletion
#
vcenter_api 6 10 "GET" $token '' $api_host "api/vcenter/cluster"
cluster_id=$(echo $response_body | jq -r --arg cluster "$(jq -c -r .tanzu.supervisor_cluster.cluster_ref $jsonFile)" '.[] | select(.name == $cluster).cluster')
#echo $cluster_id
echo "   +++ testing if variable cluster_id is not empty" ; if [ -z "$cluster_id" ] ; then exit 255 ; fi
#
vcenter_api 6 10 "POST" $token "" $api_host "api/vcenter/namespace-management/clusters/${cluster_id}?action=disable"
#
# Content Library Deletion
#
vcenter_api 6 10 "GET" $token '' $api_host "rest/com/vmware/content/subscribed-library"
content_library_id=$(echo $response_body | jq -c -r .value[0])
vcenter_api 6 10 "DELETE" $token "" $api_host "api/content/subscribed-library/${content_library_id}"
#
#
#
rm -fr terraform.tfstate .terraform.lock.hcl .terraform
rm -f /root/12_vsphere_with_tanzu