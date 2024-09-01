#!/bin/bash
jsonFile="/root/networks.json"
deployment=$(jq -c -r .deployment $jsonFile)
if [[ ${deployment} == "vsphere_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" || ${deployment} == "vsphere_alb_wo_nsx" || ${deployment} == "vsphere_tanzu_alb_wo_nsx" ]]; then
  source /nestedVsphere8/bash/tf_init_apply.sh
  #
  tf_init_apply "Build of Nested Networks - This should take less than a minute" /nestedVsphere8/04_networks /nestedVsphere8/log/04.stdout /nestedVsphere8/log/04.stderr $jsonFile
  #
  if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 04_networks configured"}' ${slack_webhook_url} >/dev/null 2>&1; fi
fi
log_file=/nestedVsphere8/log/04.stdout
jsonFile="/root/external_gw.json"
echo "Creation a content library for ubunutu - This should take less than 10 minute" | tee -a ${log_file}
echo "Starting timestamp: $(date)" | tee -a ${log_file}
sed -e "s@\${folder}@/root@" \
        -e "s/\${vsphere_host}/$(jq -r .vsphere_nested.vcsa_name $jsonFile)/" \
        -e "s/\${domain}/$(jq -r .external_gw.bind.domain $jsonFile)/" \
        -e "s/\${vsphere_username}/administrator/" \
        -e "s/\${vcenter_domain}/$(jq -r .vsphere_nested.sso.domain_name $jsonFile)/" \
        -e "s/\${vsphere_password}/${TF_VAR_vsphere_nested_password}/" \
        -e "s/\${vsphere_dc}/$(jq -r .vsphere_nested.datacenter $jsonFile)/" \
        -e "s/\${vsphere_cluster}/$(jq -r .vsphere_nested.cluster_list[0] $jsonFile)/" \
        -e "s/\${vsphere_datastore}/$(jq -r .vsphere_nested.datastore_list[0] $jsonFile)/" /nestedVsphere8/02_external_gateway/templates/load_govc_nested.sh.template | tee /root/load_govc_nested.sh > /dev/null
# create content library
cp /nestedVsphere8/02_external_gateway/lbaas/govc/govc_init.sh /root/govc_init.sh
source /root/load_govc_nested.sh
echo "" | tee ${log_file} > /dev/null
govc library.create $(jq -c -r .ubuntu_cl $jsonFile)
govc library.import $(jq -c -r .ubuntu_cl $jsonFile) $(jq -c -r .ubuntu_ova_path $jsonFile)
echo "Ending timestamp: $(date)" | tee -a ${log_file}
echo "-----------------------------------------------------" | tee -a ${log_file}
touch "/root/04_networks"
if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ubunutu content library created"}' ${slack_webhook_url} >/dev/null 2>&1; fi
