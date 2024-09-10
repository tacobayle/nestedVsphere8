#!/bin/bash
#
echo ""
echo "==> Checking Variables files"
if [ -s "/etc/config/variables.json" ]; then
  jsonFile="/etc/config/variables.json"
  jq . $jsonFile
else
  echo "/etc/config/variables.json file is empty!!"
  exit 255
fi
#
# 00_pre_check
#
if [ -f "/root/00_pre_check" ]; then
  echo "Skipping 00_pre_check"
else
  pre_check_scripts='["00.sh", "02.sh", "03.sh", "04.sh", "05.sh", "07.sh", "08.sh", "10.sh", "12.sh", "13.sh"]'
  for script in $(echo ${pre_check_scripts} | jq -c -r .[])
  do
    /bin/bash /nestedVsphere8/00_pre_check/${script}
    if [ $? -ne 0 ] ; then exit 1 ; fi
  done
fi
#
touch "/root/00_pre_check"
if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 00_pre_check done"}' ${slack_webhook_url} >/dev/null 2>&1 ; fi
#
jsonFile="/root/variables.json"
deployment=$(jq -c -r .deployment $jsonFile)
#
echo ""
echo "********* Deployment use case: ${deployment} *********"
echo ""
#
# Environment Creation
#
output_file="/root/output.txt"
#
apply_scripts='["01_underlay_vsphere_directory", "02_external_gateway", "03_nested_vsphere", "04_networks", "05_nsx_manager", "06_nsx_config", "07_nsx_alb", "08_app", "10_unmanaged_k8s_clusters", "11_nsx_alb_config", "12_vsphere_with_tanzu", "13_tkgm"]'
for folder in $(echo ${apply_scripts} | jq -c -r .[])
do
  if [ -f "/root/${folder}" ]; then
    echo "-----------------------------------------------------"
    echo "Skipping creation of ${folder}"
  else
    /bin/bash /nestedVsphere8/${folder}/apply.sh &
    if [ $? -ne 0 ] ; then
      if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: '${folder}'"}' ${slack_webhook_url} >/dev/null 2>&1; fi
      exit 1
    fi
  fi
done
#
echo ""
cat ${output_file}
#
# Transfer output to external-gw
#
echo ""
scp -o StrictHostKeyChecking=no ${output_file} ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile):/home/ubuntu/output.txt >/dev/null 2>&1
ssh -o StrictHostKeyChecking=no -t ubuntu@$(jq -c -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile) 'echo "cat /home/ubuntu/output.txt" | tee -a /home/ubuntu/.profile >/dev/null 2>&1' >/dev/null 2>&1
#
#
#
while true ; do sleep 3600 ; done