#!/bin/bash
operation="${1}"
if [[ ${operation} == "apply" ]] ; then log_file="/nestedVsphere8/log/01_folder_apply.stdout" ; fi
if [[ ${operation} == "destroy" ]] ; then log_file="/nestedVsphere8/log/01_folder_destroy.stdout" ; fi
if [[ ${operation} != "apply" && ${operation} != "destroy" ]] ; then echo "ERROR: Unsupported operation" ; exit 255 ; fi
echo '-----------------------------------------------------' | tee ${log_file}
if [[ ${operation} == "apply" ]] ; then
  echo "Creation of a folder on the underlay infrastructure - This should take less than a minute" | tee -a ${log_file}
fi
if [[ ${operation} == "destroy" ]] ; then
  echo "Deletion of a folder on the underlay infrastructure - This should take less than a minute" | tee -a ${log_file}
fi
echo "Starting timestamp: $(date)" | tee -a ${log_file}
jsonFile="/root/variables.json"
source /nestedVsphere8/bash/govc/load_govc_underlay.sh
list_folder=$(govc find -json . -type f)
if $(echo ${list_folder} | jq -e '. | any(. == "./vm/'$(jq -c -r .vsphere_underlay.folder $jsonFile)'")' >/dev/null ) ; then
  if [[ ${operation} == "apply" ]] ; then
    echo "ERROR: unable to create folder $(jq -r .vsphere_underlay.folder $jsonFile): it already exists" | tee -a ${log_file}
  fi
  if [[ ${operation} == "destroy" ]] ; then
    govc object.destroy /${vsphere_dc}/vm/$(jq -r .vsphere_underlay.folder $jsonFile) | tee -a ${log_file}
    rm /root/01_underlay_vsphere_directory
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 01_underlay_vsphere_directory destroyed"}' ${slack_webhook_url} >/dev/null 2>&1; fi
  fi
else
  if [[ ${operation} == "apply" ]] ; then
    govc folder.create /${vsphere_dc}/vm/$(jq -r .vsphere_underlay.folder $jsonFile) | tee -a ${log_file}
    if [ -z "${slack_webhook_url}" ] ; then echo "ignoring slack update" ; else curl -X POST -H 'Content-type: application/json' --data '{"text":"'$(date "+%Y-%m-%d,%H:%M:%S")', '${deployment}': 01_underlay_vsphere_directory created"}' ${slack_webhook_url} >/dev/null 2>&1; fi
  fi
  if [[ ${operation} == "destroy" ]] ; then
    echo "ERROR: unable to delete folder $(jq -r .vsphere_underlay.folder $jsonFile): it does not exist" | tee -a ${log_file}
    exit 255
  fi
fi
echo "Ending timestamp: $(date)" | tee -a ${log_file}