#!/bin/bash
#
source /home/ubuntu/lbaas/avi/alb_api.sh
#
jsonFile1="${1}"
output_json_file="${2}"
results_json="{}"
IFS=$'\n'
date_index=$(date '+%Y%m%d%H%M%S')
jsonFile="/tmp/$(basename "$0" | cut -f1 -d'.')_${date_index}.json"
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
    if [[ $(echo $response_body | jq -c -r --arg arg "${vs_name}" '.results[] | select(.name == $arg).vip_runtime[0].se_list | length') -ge 2 ]]; then
      results_json=$(echo $results_json | jq '. += {"date": "'$(date)'", "vs_name": "'${vs_name}'", "se_list":[]}')
      echo ${response_body}  | jq -c -r --arg arg "${vs_name}" '.results[] | select(.name == $arg).vip_runtime[0].se_list[].se_ref' | while read se_ref
      do
	      alb_api 3 5 "GET" "${avi_cookie_file}" "${csrftoken}" "admin" "$(jq -c -r .avi_version $jsonFile)" "" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/serviceengine/$(basename ${se_ref})"
	      results_json=$(echo $results_json | jq '.se_list += [{"se_name": "'$(echo $response_body | jq -c -r '.name')'"}]')
	      echo $results_json | tee ${output_json_file} | jq .
      done
      break
    else
      echo "retrying..."
    fi
  else
    echo "retrying..."
  fi
done
#
rm -f ${jsonFile}
rm -f ${jsonFile1}
rm -f ${avi_cookie_file}