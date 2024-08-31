#!/bin/bash
#
echo ""
echo "==> Checking Variables files"
if [ -s "/etc/config/variables.json" ]; then
  jsonFile="/etc/config/variables.json"
  jq . $jsonFile > /dev/null
  jq . $jsonFile
else
  echo "/etc/config/variables.json file is empty!!"
  exit 255
fi
#
# 00_pre_check
#
/bin/bash /nestedVsphere8/00_pre_check/00.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
jsonFile="/root/variables.json"
deployment=$(jq -c -r .deployment $jsonFile)
#
#/bin/bash /nestedVsphere8/00_pre_check/01.sh
#if [ $? -ne 0 ] ; then exit 1 ; fi
#
/bin/bash /nestedVsphere8/00_pre_check/02.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
#
/bin/bash /nestedVsphere8/00_pre_check/03.sh
if [ $? -ne 0 ] ; then exit 1 ; fi
#
if [[ ${deployment} == "vsphere_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" || ${deployment} == "vsphere_alb_wo_nsx" || ${deployment} == "vsphere_tanzu_alb_wo_nsx" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/04.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ ${deployment} == "vsphere_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/05.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ ${deployment} == "vsphere_alb_wo_nsx" || ${deployment} == "vsphere_tanzu_alb_wo_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/07.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ ${deployment} == "vsphere_alb_wo_nsx" || ${deployment} == "vsphere_tanzu_alb_wo_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/08.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ $(jq -c -r .unmanaged_k8s_status $jsonFile) == true ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/10.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ ${deployment} == "vsphere_tanzu_alb_wo_nsx" || ${deployment} == "vsphere_nsx_tanzu_alb" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/12.sh
   if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [[ ${deployment} == "vsphere_nsx_alb_telco" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/13.sh
  if [ $? -ne 0 ] ; then exit 1 ; fi
fi
#
if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 00_pre_check done"}' ${slack_webhook_url} >/dev/null 2>&1 ; fi
#
echo ""
echo "********* Deployment use case: ${deployment} *********"
echo ""
#
# Environment Creation
#
#
# 01_underlay_vsphere_directory
#
/bin/bash /nestedVsphere8/01_underlay_vsphere_directory/folder.sh apply
if [ $? -ne 0 ] ; then
  if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: vSphere folder"}' ${slack_webhook_url} >/dev/null 2>&1; fi
  exit 1
fi
#
#
#
output_file="/root/output.txt"
rm -f ${output_file}
#
# 02_external_gateway
#
/bin/bash /nestedVsphere8/02_external_gateway/apply.sh
if [ $? -ne 0 ] ; then
  if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: external-gw"}' ${slack_webhook_url} >/dev/null 2>&1; fi
  exit 1
fi
#
# 03_nested_vsphere
#
/bin/bash /nestedVsphere8/03_nested_vsphere/apply.sh
if [ $? -ne 0 ] ; then
  if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: nested vSphere"}' ${slack_webhook_url} >/dev/null 2>&1; fi
  exit 1
fi
#
# 04_networks
#
if [[ ${deployment} == "vsphere_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" || ${deployment} == "vsphere_alb_wo_nsx" || ${deployment} == "vsphere_tanzu_alb_wo_nsx" ]]; then
  /bin/bash /nestedVsphere8/04_networks/apply.sh
  if [ $? -ne 0 ] ; then
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: nested vSphere networks"}' ${slack_webhook_url} >/dev/null 2>&1; fi
    exit 1
  fi
fi
#
# 05_nsx_manager
#
if [[ ${deployment} == "vsphere_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/05_nsx_manager/apply.sh
  if [ $? -ne 0 ] ; then
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: NSX manager"}' ${slack_webhook_url} >/dev/null 2>&1; fi
    exit 1
  fi
fi
#
# 06_nsx_config
#
if [[ ${deployment} == "vsphere_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/06_nsx_config/apply.sh
  if [ $? -ne 0 ] ; then
    exit 1
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: NSX config"}' ${slack_webhook_url} >/dev/null 2>&1; fi
  fi
fi
#
# 07_nsx_alb
#
if [[ ${deployment} == "vsphere_alb_wo_nsx" || ${deployment} == "vsphere_tanzu_alb_wo_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/07_nsx_alb/apply.sh
  if [ $? -ne 0 ] ; then
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: Avi controller"}' ${slack_webhook_url} >/dev/null 2>&1; fi
    exit 1
  fi
fi
#
# 08_app
#
if [[ ${deployment} == "vsphere_alb_wo_nsx" || ${deployment} == "vsphere_tanzu_alb_wo_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/08_app/apply.sh
  if [ $? -ne 0 ] ; then
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: App servers"}' ${slack_webhook_url} >/dev/null 2>&1; fi
    exit 1
  fi
fi
#
# 09_lbaas
#
if [[ ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_tanzu_alb" ]]; then
  /bin/bash /nestedVsphere8/09_lbaas/apply.sh
  if [ $? -ne 0 ] ; then
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: LBaaS"}' ${slack_webhook_url} >/dev/null 2>&1; fi
    exit 1
  fi
fi
#
# 10_unmanaged_k8s_clusters
#
if [[ $(jq -c -r .unmanaged_k8s_status $jsonFile) == true ]]; then
  /bin/bash /nestedVsphere8/10_unmanaged_k8s_clusters/apply.sh
  if [ $? -ne 0 ] ; then
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: Unmanaged K8s clusters"}' ${slack_webhook_url} >/dev/null 2>&1; fi
    exit 1
  fi
fi
#
# 11_nsx_alb_config
#
if [[ ${deployment} == "vsphere_alb_wo_nsx" || ${deployment} == "vsphere_tanzu_alb_wo_nsx" || ${deployment} == "vsphere_nsx_alb" || ${deployment} == "vsphere_nsx_alb_telco" || ${deployment} == "vsphere_nsx_tanzu_alb" || ${deployment} == "vsphere_nsx_alb_vcd" ]]; then
  /bin/bash /nestedVsphere8/11_nsx_alb_config/apply.sh
  if [ $? -ne 0 ] ; then
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: Avi config."}' ${slack_webhook_url} >/dev/null 2>&1; fi
    exit 1
  fi
fi
#
# 12_vsphere_with_tanzu
#
if [[ ${deployment} == "vsphere_tanzu_alb_wo_nsx" || ${deployment} == "vsphere_nsx_tanzu_alb" ]]; then
  /bin/bash /nestedVsphere8/12_vsphere_with_tanzu/apply.sh 2> /nestedVsphere8/log/12_vsphere_with_tanzu.stderr 1> /nestedVsphere8/log/12_vsphere_with_tanzu.stdin
  if [ $? -ne 0 ] ; then
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: vSphere with Tanzu"}' ${slack_webhook_url} >/dev/null 2>&1; fi
    exit 1
  fi
fi
#
# 13_tkgm
#
if [[ ${deployment} == "vsphere_nsx_alb_telco" ]]; then
  /bin/bash /nestedVsphere8/13_tkgm/apply.sh
  if [ $? -ne 0 ] ; then
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': ERROR: TKGm"}' ${slack_webhook_url} >/dev/null 2>&1; fi
    exit 1
  fi
fi
#
#if [[ $(jq -c -r .avi $jsonFile) != "null" &&  $(jq -c -r .nsx $jsonFile) != "null" &&  $(jq -c -r .vcd $jsonFile) != "null" && $(jq -c -r .avi.config.cloud.type $jsonFile) == "CLOUD_NSXT" ]]; then
#  /bin/bash /nestedVsphere8/14_vcd_appliance/apply.sh
##   if [ $? -ne 0 ] ; then exit 1 ; fi
#fi
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