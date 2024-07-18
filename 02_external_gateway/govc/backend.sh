#!/bin/bash
#
date_index=$(date '+%Y%m%d%H%M%S')
jsonFile="/home/ubuntu/lbaas/govc/$(basename "$0" | cut -f1 -d'.')_${date_index}.json"
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
#
if $(jq -e '. | has("vs_name")' $jsonFile) ; then
  vs_name=$(jq -c -r .vs_name $jsonFile)
else
  "ERROR: vs_name should be defined"
  exit 255
fi
#
if [[ ${operation} != "apply" && ${operation} != "destroy" ]] ; then echo "ERROR: Unsupported operation" ; exit 255 ; fi
#
source /home/ubuntu/lbaas/govc/load_govc_nested.sh
#
if [[ ${operation} == "apply" ]] ; then
  list=$(govc find -json vm -name "${vs_name}*")
  if [[ ${list} == "null" ]] ; then
    count=$(jq -c -r .count $jsonFile)
    app_profile=$(jq -c -r .app_profile $jsonFile)
    if [[ ${app_profile} != "public" && ${app_profile} != "private" ]] ; then echo "ERROR: Unsupported app_profile" ; exit 255 ; fi
    if [[ ${app_profile} == "public" ]] ; then lbaas_segment=$(jq -r .public.lbaas_segment $jsonFile) ; fi
    if [[ ${app_profile} == "private" ]] ; then lbaas_segment=$(jq -r .private.lbaas_segment $jsonFile) ; fi
    for backend in $(seq 1 ${count})
    do
      #
      # Create cloud init file
      #
      sed -e "s/\${password}/$(jq -c -r .password $jsonFile)/" \
          -e "s/\${hostname}/${vs_name}${backend}/" \
          -e "s/\${docker_registry_username}/$(jq -r .docker_username $jsonFile)/" \
          -e "s/\${docker_registry_password}/$(jq -r .docker_password $jsonFile)/" /home/ubuntu/lbaas/govc/backend_userdata.yaml.template | tee /home/ubuntu/lbaas/govc/backend_userdata_${date_index}_${backend}.yaml > /dev/null
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
            "Value": "'$(base64 /home/ubuntu/lbaas/govc/backend_userdata_${date_index}_${backend}.yaml -w 0)'"
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
        "Name": "'${vs_name}''${backend}'"
      }'
      echo ${json_data} | jq . | tee /home/ubuntu/lbaas/govc/${vs_name}${backend}.json
      govc library.deploy -options /home/ubuntu/lbaas/govc/${vs_name}${backend}.json /avi_app/ubuntu.ova
      govc vm.change -vm "${vs_name}${backend}" -c 4 -m 4096 -e="disk.enableUUID=1"
      govc vm.disk.change -vm "${vs_name}${backend}" -disk.label "Hard disk 1" -size 10G
      govc vm.power -on=true "${vs_name}${backend}"
    done
  else
    echo "backend VM ${vs_name}* already exist"
  fi
fi
#
if [[ ${operation} == "destroy" ]] ; then
  list=$(govc find -json vm -name "${vs_name}*")
  if [[ ${list} != "null" ]] ; then
    echo $list | jq -c -r .[] | while read item
    do
      govc vm.destroy $item
    done
  else
    echo "no backend VM ${vs_name}* to be deleted"
  fi
fi