#!/bin/bash
#
IFS=$'\n'
username=$1
password=$2
ip=$3
rm -f avi_cookie.txt
#vip_ip_list="[]"
curl_output=$(curl -s -k -X POST -H "Content-Type: application/json" -d "{\"username\": \"$username\", \"password\": \"$password\"}" -c avi_cookie.txt https://$ip/login)
curl_virtualservice=$(curl -s -k -X GET -H "Content-Type: application/json" -b avi_cookie.txt https://$ip/api/virtualservice)
echo '#!/bin/bash' | tee /root/traffic_gen.sh
if [[ $(echo $curl_virtualservice | jq -c -r '.results | length') -gt 0 ]] ; then
  for vs in $(echo $curl_virtualservice | jq -c -r .results[])
  do
    for service in $(echo $vs | jq -c -r .services[])
    do
      if [[ $(echo $service | jq -c -r .port) -eq 443 ]] ; then
        #echo $service | jq .port
        #echo $vs | jq .vsvip_ref
        curl_vsvip=$(curl -s -k -X GET -H "Content-Type: application/json" -b avi_cookie.txt $(echo $vs | jq -c -r .vsvip_ref))
        #vip_ip_list=$(echo $vip_ip_list | jq '. += ['$(echo $curl_vsvip | jq .vip[0].ip_address.addr)']')
        echo "for i in {1..20}; do curl -k https://$(echo $curl_vsvip | jq -c -r .vip[0].ip_address.addr); sleep 0.5 ; done" | tee -a /root/traffic_gen.sh
      fi
    done
  done
fi
#echo $vip_ip_list | jq . | tee vip_ip_list.json