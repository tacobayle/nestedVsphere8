#!/bin/bash
#
source /nestedVsphere8/bash/avi/alb_api.sh
#
avi_controller_ip=${1}
avi_version=${2}
avi_password=${3}
avi_cloud_name=${4}
prefix=${5}
json_output_file=${6}
#
avi_cookie_file="/root/avi_$(basename $0 | cut -d"." -f1)_cookie.txt"
curl_login=$(curl -s -k -X POST -H "Content-Type: application/json" \
                                -d "{\"username\": \"admin\", \"password\": \"${avi_password}\"}" \
                                -c ${avi_cookie_file} https://${avi_controller_ip}/login)
csrftoken=$(cat ${avi_cookie_file} | grep csrftoken | awk '{print $7}')
#
echo "++++ retrieve cloud details"
alb_api 2 1 "GET" "${avi_cookie_file}" "${csrftoken}" "admin" "${avi_version}" "" "${avi_controller_ip}" "api/cloud"
cloud_url=$(echo $response_body | jq -c -r --arg avi_cloud_name "${avi_cloud_name}" '.results[] | select( .name == $avi_cloud_name ) | .url')
echo "  ${cloud_url}"
#
echo "++++ retrieve network url"
alb_api 2 1 "GET" "${avi_cookie_file}" "${csrftoken}" "admin" "${avi_version}" "" "${avi_controller_ip}" "api/network?page_size=-1"
network_name=$(echo $response_body | jq -c -r --arg cloud_url "${cloud_url}" \
                                              --arg prefix "${prefix}" \
                                    '.results[] | select(.cloud_ref == $cloud_url and .configured_subnets != null and .configured_subnets[0].prefix.ip_addr.addr == $prefix)' | jq .name)
echo '{"network_name":'${network_name}'}' | tee ${json_output_file}
#
rm -f ${avi_cookie_file}