#!/bin/bash
#
# $1 is the password
# $2 is the VCD FQDN
#
#
# Tested with VCD 10.4
#
retry=6
pause=10
attempt=0
endpoint="api/1.0.0/sessions"
username=root
password=$1
url=$2
while true ; do
  response=$(curl -k -s --write-out "\n%{http_code}" -X POST -u "$username:$password" https://$url:5480/$endpoint -H "Content-Type: application/json")
  http_code=$(tail -n1 <<< "$response")
  content=$(sed '$ d' <<< "$response")
  if [[ $http_code == 20[0-9] ]] ; then
    token=$(echo $content | jq .authToken | tr -d \")
    if [[ ${#token} -eq 43 ]] ; then
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
