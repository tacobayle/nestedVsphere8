#!/bin/bash
#
source /home/ubuntu/lbaas/nsx/nsx_api.sh
source /home/ubuntu/lbaas/avi/alb_api.sh
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
avi_cookie_file="/tmp/avi_$(basename $0 | cut -d"." -f1)_${date_index}_cookie.txt"
curl_login=$(curl -s -k -X POST -H "Content-Type: application/json" \
                                -d "{\"username\": \"$(jq -c -r .avi_username $jsonFile)\", \"password\": \"$(jq -c -r .avi_password $jsonFile)\"}" \
                                -c ${avi_cookie_file} https://$(jq -c -r .avi_nested_ip $jsonFile)/login)
csrftoken=$(cat ${avi_cookie_file} | grep csrftoken | awk '{print $7}')
#
while true
do
  alb_api 3 5 "GET" "${avi_cookie_file}" "${csrftoken}" "$(jq -c -r .avi_tenant $jsonFile)" "$(jq -c -r .avi_version $jsonFile)" "" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/virtualservice?page_size=-1"
  if [[ $(echo $response_body | jq -c -r '.results | length') -gt 0 && $(echo $response_body | jq -c -r --arg arg "${vs_name}" '[.results[] | select(.name == $arg).name] | length') -eq 1 ]]; then
    vsvip_ref=$(echo $response_body | jq -c -r --arg arg "${vs_name}" '.results[] | select(.name == $arg).vsvip_ref')
    alb_api 3 5 "GET" "${avi_cookie_file}" "${csrftoken}" "$(jq -c -r .avi_tenant $jsonFile)" "$(jq -c -r .avi_version $jsonFile)" "" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/vsvip/$(basename ${vsvip_ref})"
    ip_vip=$(echo ${response_body} | jq -c -r .vip[0].ip_address.addr)
    tier1_name=$(echo ${response_body} | jq -c -r .tier1_lr)
    if [[ -z "${ip_vip}" || -z "${tier1_name}" ]]; then
      echo "retrying..."
    else
      break
    fi
  else
    echo "retrying..."
  fi
done
#

#
#nsx_api 2 2 "GET" $cookies_file $headers_file "" $(jq -c -r .nsx_nested_ip $jsonFile) "policy/api/v1/infra/tier-1s"
#tier1_id=$(echo $response_body | jq -c -r --arg arg "${tier1_name}" '.results[] | select(.display_name == $arg) | .id')
#
while true
do
  nsx_api 2 2 "GET" $cookies_file $headers_file "${json_data}" $(jq -c -r .nsx_nested_ip $jsonFile) "policy/api/v1/infra/tier-1s/$(basename ${tier1_name})/static-routes"
  next_hops=$(echo $response_body | jq -c -r --arg arg "${ip_vip}/32" '[.results[] | select(.network == $arg) | .next_hops[].ip_address]')
  if [ -z "${next_hops}" ]; then
    echo "retrying..."
  else
    results_json=$(echo $results_json | jq '. += {"date": "'$(date)'", "vs_name": "'${vs_name}'", "vsvip": "'${ip_vip}'/32", "next_hops": '${next_hops}'}')
    echo $results_json | tee ${output_json_file} | jq .
    break
  fi
  sleep 10
done
#
rm -f ${jsonFile}
rm -f ${jsonFile1}
rm -f $cookies_file $headers_file ${avi_cookie_file}