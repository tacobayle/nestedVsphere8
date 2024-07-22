#!/bin/bash
#
source /home/ubuntu/lbaas/avi/alb_api.sh
#
date_index=$(date '+%Y%m%d%H%M%S')
jsonFile="/home/ubuntu/lbaas/avi/$(basename "$0" | cut -f1 -d'.')_${date_index}.json"
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
operation=$(jq -c -r .operation $jsonFile)
if $(jq -e '. | has("vs_name")' $jsonFile) ; then
  vs_name=$(jq -c -r .vs_name $jsonFile)
else
  "ERROR: vs_name should be defined"
  exit 255
fi
#
if [[ ${operation} != "apply" && ${operation} != "destroy" ]] ; then echo "ERROR: Unsupported operation" ; exit 255 ; fi
#
avi_cookie_file="/tmp/avi_$(basename $0 | cut -d"." -f1)_${date_index}_cookie.txt"
curl_login=$(curl -s -k -X POST -H "Content-Type: application/json" \
                                -d "{\"username\": \"$(jq -c -r .avi_username $jsonFile)\", \"password\": \"$(jq -c -r .avi_password $jsonFile)\"}" \
                                -c ${avi_cookie_file} https://$(jq -c -r .avi_nested_ip $jsonFile)/login)
csrftoken=$(cat ${avi_cookie_file} | grep csrftoken | awk '{print $7}')
if [[ ${operation} == "apply" ]] ; then
  alb_api 3 5 "GET" "${avi_cookie_file}" "${csrftoken}" "$(jq -c -r .avi_tenant $jsonFile)" "$(jq -c -r .avi_version $jsonFile)" "" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/virtualservice?page_size=-1"
  if [[ $(echo $response_body | jq -c -r --arg arg "${vs_name}" '[.results[] | select(.name == $arg).name] | length') -eq 1 ]]; then
    echo "VS ${vs_name} already exist"
  else
    app_profile=$(jq -c -r .app_profile $jsonFile)
    if [[ ${app_profile} != "public" && ${app_profile} != "private" ]] ; then echo "ERROR: Unsupported app_profile" ; exit 255 ; fi
    if [[ ${app_profile} == "public" ]] ; then
      avi_vip_cidr=$(jq -r .public.avi_vip_cidr $jsonFile)
      tier1_name=$(jq -r .public.avi_tier1 $jsonFile)
    fi
    if [[ ${app_profile} == "private" ]] ; then
      avi_vip_cidr=$(jq -r .private.avi_vip_cidr $jsonFile)
      tier1_name=$(jq -r .private.avi_tier1 $jsonFile)
    fi
    json_data='
    {
      "host": "'$(jq -c -r .nsx_nested_ip $jsonFile)'",
      "username": "'$(jq -c -r .nsx_username $jsonFile)'",
      "password": "'$(jq -c -r .nsx_password $jsonFile)'"
    }'
    alb_api 3 5 "POST" "${avi_cookie_file}" "${csrftoken}" "$(jq -c -r .avi_tenant $jsonFile)" "$(jq -c -r .avi_version $jsonFile)" "${json_data}" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/nsxt/tier1s?page_size=-1"
    tier1_id=$(echo $response_body | jq -c -r --arg arg ${tier1_name} '.resource.nsxt_tier1routers[] | select(.name == $arg).id' )
    alb_api 3 5 "POST" "${avi_cookie_file}" "${csrftoken}" "$(jq -c -r .avi_tenant $jsonFile)" "$(jq -c -r .avi_version $jsonFile)" "${json_data}" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/nsxt/groups?page_size=-1"
    group_id=$(echo $response_body | jq -c -r --arg arg ${vs_name} '.resource.nsxt_groups[] | select(.name == $arg).id' )
    json_data='
    {
      "model_name": "VirtualService",
      "data": {
        "name": "'${vs_name}'",
        "enabled": true,
        "cloud_ref": "/api/cloud/?name='$(jq -c -r .avi_cloud $jsonFile)'",
        "ssl_profile_ref": "/api/sslprofile/?name=System-Standard",
        "analytics_policy": {
            "udf_log_throttle": 10,
            "metrics_realtime_update": {
                "duration": 0,
                "enabled": true
            },
            "significant_log_throttle": 0,
            "client_insights": "NO_INSIGHTS",
            "full_client_logs": {
                "duration": 0,
                "throttle": 10,
                "enabled": true
            }
        },
        "services": [
          {
            "enable_ssl": false,
            "port": 80
          },
          {
            "port": 443,
            "enable_ssl": true
          }
        ],
        "vsvip_ref_data": {
          "name": "vsvip-'${vs_name}'",
          "cloud_ref": "/api/cloud/?name='$(jq -c -r .avi_cloud $jsonFile)'",
          "tier1_lr": "'${tier1_id}'",
          "vip":
            [
              {
                "auto_allocate_ip": true,
                "vip_id": "1",
                "ipam_network_subnet":
                {
                  "subnet":
                  {
                    "mask": "'$(echo ${avi_vip_cidr} | cut -d"/" -f2)'",
                    "ip_addr":
                    {
                      "type": "V4",
                      "addr": "'$(echo ${avi_vip_cidr} | cut -d"/" -f1)'"
                    }
                  }
                }
              }
            ],
          "dns_info": [
            {
              "fqdn": "'${vs_name}'.'$(jq -c -r .avi_domain $jsonFile)'"
            }
          ]
        },
        "pool_ref_data": {
          "name": "'${vs_name}'-pool",
          "enabled": true,
          "tier1_lr": "'${tier1_id}'",
          "cloud_ref": "/api/cloud/?name='$(jq -c -r .avi_cloud $jsonFile)'",
          "lb_algorithm": "LB_ALGORITHM_LEAST_CONNECTIONS",
          "nsx_securitygroup": ["'${group_id}'"],
          "default_server_port": 80
        }
      }
    }'
    if [[ $(jq -c -r .cert $jsonFile) == "self-signed" ]] ; then
      json_data=$(echo ${json_data} | jq -c -r '.data += {"ssl_key_and_certificate_refs": ["/api/sslkeyandcertificate/?name=System-Default-Cert"]}')
    fi
    if [[ $(jq -c -r .cert $jsonFile) == "new-cert" ]] ; then
      json_data=$(echo ${json_data} | jq -c -r '.data += {"ssl_key_and_certificate_refs": ["/api/sslkeyandcertificate/?name=System-Default-Cert"]}')
      # use case with cert automation
    fi
    if [[ ${app_profile} == "public" ]] ; then
      json_data=$(echo ${json_data} | jq -c -r '.data += {"waf_policy_ref": "/api/wafpolicy/?name=System-WAF-Policy"}')
      json_data=$(echo ${json_data} | jq -c -r '.data += {"se_group_ref": "/api/serviceenginegroup/?name=public"}')
    fi
    if [[ ${app_profile} == "private" ]] ; then
      json_data=$(echo ${json_data} | jq -c -r '.data += {"se_group_ref": "/api/serviceenginegroup/?name=private"}')
    fi
    alb_api 3 5 "POST" "${avi_cookie_file}" "${csrftoken}" "$(jq -c -r .avi_tenant $jsonFile)" "$(jq -c -r .avi_version $jsonFile)" "${json_data}" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/macro"
  fi
fi
#
if [[ ${operation} == "destroy" ]] ; then
  alb_api 3 5 "GET" "${avi_cookie_file}" "${csrftoken}" "$(jq -c -r .avi_tenant $jsonFile)" "$(jq -c -r .avi_version $jsonFile)" "" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/virtualservice?page_size=-1"
  if [[ $(echo $response_body | jq -c -r --arg arg "${vs_name}" '[.results[] | select(.name == $arg).name] | length') -eq 1 ]]; then
    json_data='
    {
      "model_name": "VirtualService",
      "data": {
        "uuid": "'$(echo $response_body | jq -c -r --arg arg "${vs_name}" '.results[] | select(.name == $arg).uuid')'"
      }
    }'
    alb_api 3 5 "DELETE" "${avi_cookie_file}" "${csrftoken}" "$(jq -c -r .avi_tenant $jsonFile)" "$(jq -c -r .avi_version $jsonFile)" "${json_data}" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/macro"
  else
    echo "no VS ${vs_name}* to be deleted"
  fi
fi