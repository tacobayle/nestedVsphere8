#!/bin/bash
#
source /nestedVsphere8/bash/nsx/nsx_api.sh
#
nsx_nested_ip=${1}
nsx_password=${2}
display_name=${3}
cert_path_file=${4}
key_path_file=${5}
key_path_passphrase=${6}
#
cookies_file="/root/nsx_$(basename $0 | cut -d"." -f1)_cookie.txt"
headers_file="/root/nsx_$(basename $0 | cut -d"." -f1)_header.txt"
rm -f $cookies_file $headers_file
/bin/bash /nestedVsphere8/bash/nsx/create_nsx_api_session.sh admin $nsx_password $nsx_nested_ip $cookies_file $headers_file
#
json_data='
{
  "pem_encoded": "'$(awk '{printf "%s\\n", $0}' ${cert_path_file})'",
  "private_key": "'$(awk '{printf "%s\\n", $0}' ${key_path_file})'",
  "display_name": "'${display_name}'",
  "purpose": "signing-ca",
  "passphrase": "'$(cat ${key_path_passphrase})'"
}'
echo ${json_data} | jq .
#
nsx_api 2 2 "POST" $cookies_file $headers_file "${json_data}" $nsx_nested_ip "api/v1/trust-management/certificates/${display_name}?action=import_trusted_ca"