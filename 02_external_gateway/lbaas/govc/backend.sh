#!/bin/bash
#
jsonFile="${1}"
#
operation=$(jq -c -r .operation $jsonFile)
vs_name=$(jq -c -r .vs_name $jsonFile)
#
source /home/ubuntu/lbaas/govc/load_govc_nested.sh
#
if [[ ${operation} == "apply" ]] ; then
  list=$(govc find -json vm -name "${vs_name}*")
  if [[ ${list} != "null" ]] ; then
    echo $list | jq -c -r .[] | while read item
    do
      govc vm.destroy $item
    done
  fi
  list=$(govc find -json vm -name "${vs_name}*")
  if [[ ${list} == "null" ]] ; then
    count=$(jq -c -r .count $jsonFile)
    app_profile=$(jq -c -r .app_profile $jsonFile)
    if [[ ${app_profile} != "public" && ${app_profile} != "private" ]] ; then echo "ERROR: Unsupported app_profile" ; exit 255 ; fi
    if [[ ${app_profile} == "public" ]] ; then lbaas_segment=$(jq -r .public.lbaas_segment $jsonFile) ; fi
    if [[ ${app_profile} == "private" ]] ; then lbaas_segment=$(jq -r .private.lbaas_segment $jsonFile) ; fi
    for backend in $(seq 1 ${count})
    do
      list=$(govc find -json vm -name "unassigned*")
      if [[ ${list} != "null" && $(echo ${list} | jq -c -r '. | length') -gt 0 ]] ; then
        govc vm.change -vm $(echo ${list} | jq -c -r .[0]) -c 4 -m 4096 -e="disk.enableUUID=1"
        govc vm.disk.change -vm $(echo ${list} | jq -c -r .[0]) -disk.label "Hard disk 1" -size 10G
        govc object.rename $(echo ${list} | jq -c -r .[0]) "${vs_name}-${backend}"
        govc vm.power -on=true "${vs_name}-${backend}"
        govc vm.network.change -vm "${vs_name}-${backend}" -net ${lbaas_segment} ethernet-0
      else
        #
        # Create cloud init file
        #
        sed -e "s/\${password}/$(jq -c -r .password $jsonFile)/" \
            -e "s/\${hostname}/${vs_name}${backend}/" \
            -e "s/\${docker_registry_username}/$(jq -r .docker_username $jsonFile)/" \
            -e "s/\${docker_registry_password}/$(jq -r .docker_password $jsonFile)/" /home/ubuntu/lbaas/govc/backend_userdata.yaml.template | tee /tmp/backend_userdata_${vs_name}_${backend}.yaml > /dev/null
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
              "Value": "'$(base64 /tmp/backend_userdata_${vs_name}_${backend}.yaml -w 0)'"
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
          "Name": "'${vs_name}'-'${backend}'"
        }'
        echo ${json_data} | jq . | tee /tmp/${vs_name}_${backend}.json
        govc library.deploy -options /tmp/${vs_name}_${backend}.json /lbaas/focal-server-cloudimg-amd64
        govc vm.change -vm "${vs_name}-${backend}" -c 4 -m 4096 -e="disk.enableUUID=1"
        govc vm.disk.change -vm "${vs_name}-${backend}" -disk.label "Hard disk 1" -size 10G
        govc vm.power -on=true "${vs_name}-${backend}"
      fi
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