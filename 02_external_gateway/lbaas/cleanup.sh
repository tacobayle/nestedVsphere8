#!/bin/bash
#
source /home/ubuntu/lbaas/avi/alb_api.sh
source /home/ubuntu/lbaas/nsx/nsx_api.sh
source /home/ubuntu/lbaas/govc/load_govc_nested.sh
#
jsonFile="/home/ubuntu/lbaas/lbaas.json"
if [ -s "${jsonFile}" ]; then
  jq . $jsonFile > /dev/null
else
  echo "ERROR: jsonFile file is not present"
  exit 255
fi
#
IFS=$'\n'
date_index=$(date '+%Y%m%d%H%M%S')
#
while true
do
  if [[ -z "$(ps -ef | grep backend.sh | grep -v grep)" && -z "$(ps -ef | grep vs.sh | grep -v grep)" && -z "$(ps -ef | grep nsx_group.sh | grep -v grep)" ]]; then
    echo "VM is not creating"
    avi_cookie_file="/tmp/avi_$(basename $0 | cut -d"." -f1)_${date_index}_cookie.txt"
    curl_login=$(curl -s -k -X POST -H "Content-Type: application/json" \
                                    -d "{\"username\": \"$(jq -c -r .avi_username $jsonFile)\", \"password\": \"$(jq -c -r .avi_password $jsonFile)\"}" \
                                    -c ${avi_cookie_file} https://$(jq -c -r .avi_nested_ip $jsonFile)/login)
    csrftoken=$(cat ${avi_cookie_file} | grep csrftoken | awk '{print $7}')
    alb_api 3 5 "GET" "${avi_cookie_file}" "${csrftoken}" "$(jq -c -r .avi_tenant $jsonFile)" "$(jq -c -r .avi_version $jsonFile)" "" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/virtualservice?page_size=-1"
    for vs in $(echo $response_body | jq -c -r '.results[]')
    do
      vs_name=$(echo ${vs} | jq -c -r '.name')
      json_data='
      {
        "model_name": "VirtualService",
        "data": {
          "uuid": "'$(echo ${vs} | jq -c -r '.uuid')'"
        }
      }'
      echo "delete Avi vs name ${vs_name}"
      alb_api 3 5 "DELETE" "${avi_cookie_file}" "${csrftoken}" "$(jq -c -r .avi_tenant $jsonFile)" "$(jq -c -r .avi_version $jsonFile)" "${json_data}" "$(jq -c -r .avi_nested_ip $jsonFile)" "api/macro"
      #
      cookies_file="/tmp/$(basename "$0" | cut -f1 -d'.')_${date_index}_cookies.txt"
      headers_file="/tmp/$(basename "$0" | cut -f1 -d'.')_${date_index}_headers.txt"
      sudo rm -f $cookies_file $headers_file
      #
      /bin/bash /home/ubuntu/lbaas/nsx/create_nsx_api_session.sh $(jq -c -r .nsx_username $jsonFile) $(jq -c -r .nsx_password $jsonFile) $(jq -c -r .nsx_nested_ip $jsonFile) $cookies_file $headers_file
      echo "delete NSX group name ${vs_name}"
      nsx_api 2 2 "DELETE" $cookies_file $headers_file "" $(jq -c -r .nsx_nested_ip $jsonFile) "policy/api/v1/infra/domains/default/groups/${vs_name}"
      #
      list=$(govc find -json vm -name "${vs_name}*")
      if [[ ${list} != "null" ]] ; then
        echo $list | jq -c -r .[] | while read item
        do
           echo "delete vSphere VM name ${item}"
          govc vm.destroy $item
        done
      fi
    done
    list=$(govc find -json vm -name "unassigned*")
    if [[ ${list} != "null" && $(echo ${list} | jq -c -r '. | length') -eq 6 ]] ; then
      echo "clean-up done"
      break
    else
      backend=$(uuidgen)
      lbaas_segment=$(jq -r .public.lbaas_segment $jsonFile)
      sed -e "s/\${password}/$(jq -c -r .password $jsonFile)/" \
          -e "s/\${hostname}/${vs_name}${backend}/" \
          -e "s/\${docker_registry_username}/$(jq -r .docker_username $jsonFile)/" \
          -e "s/\${docker_registry_password}/$(jq -r .docker_password $jsonFile)/" /home/ubuntu/lbaas/govc/backend_userdata.yaml.template | tee /tmp/backend_userdata_${backend}.yaml > /dev/null
      #
      json_data='
      {
        "DiskProvisioning": "thin",
        "IPAllocationPolicy": "dhcpPolicy",
        "IPProtocol": "IPv4",
        "PropertyMapping": [
          {
            "Key": "instance-id",
            "Value": "id-ovf"
          },
          {
            "Key": "hostname",
            "Value": "'${vs_name}''${backend}'"
          },
          {
            "Key": "seedfrom",
            "Value": ""
          },
          {
            "Key": "public-keys",
            "Value": ""
          },
          {
            "Key": "user-data",
            "Value": "'$(base64 /tmp/backend_userdata_${backend}.yaml -w 0)'"
          },
          {
            "Key": "password",
            "Value": "'$(jq -c -r .password $jsonFile)'"
          }
        ],
        "NetworkMapping": [
          {
            "Name": "VM Network",
            "Network": "'${lbaas_segment}'"
          }
        ],
        "MarkAsTemplate": false,
        "PowerOn": false,
        "InjectOvfEnv": false,
        "WaitForIP": false,
        "Name": "unassigned-'${backend}'"
      }'
      echo ${json_data} | jq . | tee /tmp/${vs_name}${backend}.json
      govc library.deploy -options /tmp/${vs_name}${backend}.json /$(jq -c -r .ubuntu_cl $jsonFile)/$(basename $(jq -c -r .ubuntu_ova_path $jsonFile) .ova)
    fi
  else
    echo "waiting for on-going stuff"
    sleep 10
  fi
done