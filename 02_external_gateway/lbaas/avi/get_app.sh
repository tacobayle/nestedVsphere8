#!/bin/bash
#
source /home/ubuntu/lbaas/avi/alb_api.sh
#
jsonFile="/home/ubuntu/lbaas/lbaas.json"
output_json_file="${1}"
if [ -s "${jsonFile}" ]; then
  jq . $jsonFile > /dev/null
else
  echo "ERROR: jsonFile file is not present"
  exit 255
fi
#
IFS=$'\n'
#
while true
do
  if [[ -z "$(ps -ef | grep vs.sh | grep -v grep)" ]]; then
    echo "VM is not creating"
    avi_cookie_file="/tmp/avi_$(basename $0 | cut -d"." -f1)_${date_index}_cookie.txt"
    curl_login=$(curl -s -k -X POST -H "Content-Type: application/json" \
                                    -d "{\"username\": \"$(jq -c -r .avi_username $jsonFile)\", \"password\": \"$(jq -c -r .avi_password $jsonFile)\"}" \
                                    -c ${avi_cookie_file} https://$(jq -c -r .avi_nested_ip $jsonFile)/login)
    csrftoken=$(cat ${avi_cookie_file} | grep csrftoken | awk '{print $7}')
    alb_api 3 5 "GET" "${avi_cookie_file}" "${csrftoken}" "$(jq -c -r .avi_tenant $jsonFile)" "$(jq -c -r .avi_version $jsonFile)" "" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/virtualservice?page_size=-1"
    vs_count=$(echo $response_body | jq -c -r '.count')
    results_json='{"count": "'${vs_count}'", "results": []}'
    for vs in $(echo $response_body | jq -c -r '.results[]')
    do
      results_json=$(echo ${results_json} | jq -c -r '.results += [{"app_name": "'$(echo ${vs} | jq -c -r '.name')'"}]')
    done
    echo $results_json | tee ${output_json_file} | jq .
    break
  else
    echo "waiting for on-going stuff"
    sleep 10
  fi
done