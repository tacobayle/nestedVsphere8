#!/bin/bash
#
source /home/ubuntu/govc/load_govc_nested.sh
date_index=$(date '+%Y%m%d%H%M%S')
jsonFile="/home/ubuntu/govc/$(basename "$0" | cut -f1 -d'.')_${date_index}.json"
jsonFile1="${1}"
if [ -s "${jsonFile1}" ]; then
  jq . $jsonFile1 > /dev/null
else
  echo "ERROR: jsonFile1 file is not present"
  exit 255
fi
#
jsonFile2="/home/ubuntu/govc/lbaas.json"
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
if [[ ${operation} != "apply" && ${operation} != "destroy" ]] ; then echo "ERROR: Unsupported operation" ; exit 255 ; fi
#
count=$(jq -c -r .count $jsonFile)
#
for backend in $(seq 1 ${count})
do
  #
  # Create cloud init file
  #
  if [[ $(jq -c -r .lbaas_current_ip $jsonFile) == $(jq -c -r .lbaas_last_ip $jsonFile) ]] ; then
    echo "no more IP available in the pool"
    exit 255
  else
    sed -e "s/\${password}/$(jq -c -r .password $jsonFile)/" \
        -e "s/\${hostname}/backend-0${backend}/" \
        -e "s/\${ip}/$(jq -c -r .lbaas_current_ip $jsonFile)/" \
        -e "s/\${prefix}/$(jq -c -r .lbaas_prefix $jsonFile)/" \
        -e "s/\${default_gw}/$(jq -c -r .lbaas_gw $jsonFile)/" \
        -e "s/\${dns}/$(jq -r .lbaas_dns $jsonFile)/" \
        -e "s/\${docker_registry_username}/$(jq -r .docker_username $jsonFile)/" \
        -e "s/\${docker_registry_password}/$(jq -r .docker_password $jsonFile)/" /home/ubuntu/govc/backend_userdata.yaml.template | tee /home/ubuntu/govc/backend_userdata_${date_index}_${backend}.yaml > /dev/null
    #
    json_data='
    {
      "DiskProvisioning": "thin",
      "IPAllocationPolicy": "fixedPolicy",
      "IPProtocol": "IPv4",
      "PropertyMapping": [
        {
          "Key": "instance-id",
          "Value": "id-ovf"
        },
        {
          "Key": "hostname",
          "Value": "backend-0'${backend}'"
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
          "Value": "'$(base64 /home/ubuntu/govc/backend_userdata_${date_index}_${backend}.yaml -w 0)'"
        },
        {
          "Key": "password",
          "Value": "'$(jq -c -r .password $jsonFile)'"
        }
      ],
      "NetworkMapping": [
        {
          "Name": "VM Network",
          "Network": "'$(jq -c -r .lbaas_segment $jsonFile)'"
        }
      ],
      "MarkAsTemplate": false,
      "PowerOn": false,
      "InjectOvfEnv": false,
      "WaitForIP": false,
      "Name": "backend-0'${backend}'"
    }'
    echo ${json_data} | jq . | tee /home/ubuntu/govc/backend-0${backend}.json
    # increment lbaas_current_ip in json file
    new_ip=$(jq '. += {"lbaas_current_ip": "'$(nextip $(jq -c -r '.lbaas_current_ip' ${jsonFile}))'"}' $jsonFile)
    echo ${new_ip} | tee $jsonFile
    echo ${new_ip} | tee $jsonFile2
    govc library.deploy -options /home/ubuntu/govc/backend-0${backend}.json /avi_app/ubuntu.ova
    govc vm.power -on=true "backend-0${backend}"
  fi
done
