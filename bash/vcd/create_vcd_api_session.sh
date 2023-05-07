#!/bin/bash
#
# $1 is the password
# $2 is the VCD FQDN
# $3 is the API version
#
#
# Tested with VCD 10.4
#
retry=6
pause=10
attempt=0
endpoint="cloudapi/1.0.0/sessions/provider"
username=administrator
password=$1
url=$2
api_version=$3
while true ; do
  rm -f headers.txt
  response=$(curl -k --write-out "\n%{http_code}" -s -X POST https://$url/cloudapi/1.0.0/sessions/provider -H "Accept: application/json;version=$api_version" -u "administrator@system:$password" -D headers.txt)
  http_code=$(tail -n1 <<< "$response")
  content=$(sed '$ d' <<< "$response")
  if [[ $http_code == 20[0-9] ]] ; then
    token=$(cat headers.txt | grep "X-VMWARE-VCLOUD-ACCESS-TOKEN:" | cut -d" " -f2 | tr -d '[:cntrl:]')
    if [[ ${#token} -eq 612 ]] ; then
      echo $token
      break
    fi
  fi
  if [ $attempt -eq $retry ]; then
    echo "  FAILED to create VCD API session failed, http_response_code: $http_code"
    exit 255
  fi
  sleep $pause
  ((attempt++))
done
