#!/bin/bash
#
source /home/ubuntu/lbaas/nsx/nsx_api.sh
#
results_json="{}"
output_json_file="${2}"
IFS=$'\n'
date_index=$(date '+%Y%m%d%H%M%S')
jsonFile="/tmp/$(basename "$0" | cut -f1 -d'.')_${date_index}.json"
jsonFile1="${1}"
if [ -s "${jsonFile1}" ]; then
  jq . $jsonFile1 > /dev/null
else
  echo "ERROR: jsonFile1 file is not present"
  exit 255
fi
#
jsonFile2="/home/ubuntu/lbaas/lbaas.json"
if [ -s "${jsonFile2}" ]; then
  jq . $jsonFile2 > /dev/null
else
  echo "ERROR: jsonFile2 file is not present"
  exit 255
fi
#
jq -s '.[0] * .[1]' ${jsonFile1} ${jsonFile2} | tee ${jsonFile}
#
if $(jq -e '. | has("vs_name")' $jsonFile) ; then
  vs_name=$(jq -c -r .vs_name $jsonFile)
else
  "ERROR: vs_name should be defined"
  exit 255
fi
#
cookies_file="/tmp/$(basename "$0" | cut -f1 -d'.')_${date_index}_cookies.txt"
headers_file="/tmp/$(basename "$0" | cut -f1 -d'.')_${date_index}_headers.txt"
rm -f $cookies_file $headers_file
#
/bin/bash /home/ubuntu/lbaas/nsx/create_nsx_api_session.sh $(jq -c -r .nsx_username $jsonFile) $(jq -c -r .nsx_password $jsonFile) $(jq -c -r .nsx_nested_ip $jsonFile) $cookies_file $headers_file
#
sleep 5
while true
do
  if [ -z "$(ps -ef | grep ${vs_name} | grep backend.sh | grep -v grep)" ]; then
    sleep 5
    echo "VM is not creating"
    vm_count=0
    ip_count=1
    while [[ ${vm_count} != ${ip_count} ]] ; do
      nsx_api 2 2 "GET" $cookies_file $headers_file "${json_data}" $(jq -c -r .nsx_nested_ip $jsonFile) "policy/api/v1/infra/domains/default/groups/${vs_name}/members/virtual-machines"
      vm_count=$(echo $response_body | jq -c -r '.results | length')
      nsx_api 2 2 "GET" $cookies_file $headers_file "${json_data}" $(jq -c -r .nsx_nested_ip $jsonFile) "policy/api/v1/infra/domains/default/groups/${vs_name}/members/ip-addresses"
      ip_count=$(echo $response_body | jq -c -r '.results | length')
      vm_ips=$(echo $response_body | jq -c -r '.results')
      sleep 10
    done
    results_json=$(echo $results_json | jq '. += {"date": "'$(date)'", "vs_name": "'${vs_name}'", "vm_count": "'${vm_count}'", "vm_ips": '${vm_ips}'}')
    echo $results_json | tee ${output_json_file} | jq .
    break
  else
    echo "VM is creating"
  fi
  sleep 10
done
#
rm -f ${jsonFile}
rm -f ${jsonFile1}
rm -f $cookies_file $headers_file