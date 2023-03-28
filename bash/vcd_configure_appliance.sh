#!/bin/bash
#
jsonFile="/root/vcd.json"
#
vcd_nested_ip=$(jq -r .vsphere_underlay.networks.vsphere.management.vcd_nested_ip $jsonFile)
vcd_root_password=$TF_VAR_vcd_root_password
dbPassword=$TF_VAR_vcd_dbPassword
username=administrator
vcd_administrator_password=$TF_VAR_vcd_administrator_password
#
#
#
vcd_json_config_appliance="{\"applianceType\": \"primary\"}"
nfs=$(jq -r .vsphere_underlay.networks.vsphere.management.external_gw_ip $jsonFile)
vcd_json_config_appliance=$(echo $vcd_json_config_appliance | jq '. += {"storage": {"nfs": "'$(echo $nfs)':/nfs/vCDspace"}}')
vcd_json_config_appliance=$(echo $vcd_json_config_appliance | jq '. += {"appliance": {"dbPassword": "'$(echo $dbPassword)'", "ceip": false}}')
vcd_json_config_appliance=$(echo $vcd_json_config_appliance | jq '. += {"sysAdmin": {"username": "'$(echo $username)'", "password": "'$(echo $vcd_administrator_password)'", "fullName": "cloud administrator", "email": "my-email@my-company.com"}}')
vcd_json_config_appliance=$(echo $vcd_json_config_appliance | jq '. += {"installation": {"name": "vcd1", "id": 1}}')
#{
#    "applianceType": "primary",
#    "storage": {
#        "nfs": "192.168.100.1:/data/transfer"
#    },
#    "appliance": {
#        "dbPassword": "vcloud",
#        "ceip": true
#    },
#    "sysAdmin": {
#        "username": "administrator",
#        "password": "secret-password",
#        "fullName": "cloud administrator",
#        "email": "my-email@my-company.com"
#    },
#    "installation": {
#        "name": "vcd5",
#        "id": 5
#    }
#}
echo "waiting for 120 seconds"
sleep 120
token=$(/nestedVsphere8/bash/create_vcd_appliance_api_session.sh "$vcd_root_password" "$vcd_nested_ip")
echo $vcd_json_config_appliance | jq -c -r .
response=$(curl -k  -s --write-out "\n%{http_code}" -v -X POST -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d "$(echo $vcd_json_config_appliance | jq -c -r .)" https://$url:5480/api/1.0.0/systemSetup)
http_code=$(tail -n1 <<< "$response")
echo $http_code
content=$(sed '$ d' <<< "$response")
echo $content
if [[ $http_code == 20[0-9] ]] ; then
  location=$(echo $content | grep "Location: " | cut -d" " -f3)
  retry=5
  pause=60
  attempt=0
  while true ; do
    response=$(curl -k -s --write-out "\n%{http_code}" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $token" $location)
    http_code=$(tail -n1 <<< "$response")
    content=$(sed '$ d' <<< "$response")
    if [[ $(echo $response | jq -r .result.message) == "SystemSetup has completed successfully" ]] ; then
      echo "VCD appliance configured successfully"
      break
    fi
    if [ $attempt -eq $retry ]; then
      echo "FAILED to configure VCD appliance after $retry retries"
      exit 255
    fi
    sleep $pause
    ((attempt++))
  done
else
  echo "VCD appliance config. API call failed"
fi