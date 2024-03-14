#!/bin/bash
#
# CA private key and cert creation
#
directory="/home/ubuntu/openssl/cert"
ca_name="My-Root-CA"
CN="My Root CA"
C="FR"
ST="Paris"
L="Paris"
O="MyOrganisation"
key_size=4096
ca_cert_days=1826
ca_private_key_passphrase=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12) >/dev/null 2>&1
rm -fr ${directory}
mkdir -p ${directory}
echo ${ca_private_key_passphrase} | tee ${directory}/ca_private_key_passphrase.txt >/dev/null 2>&1
openssl genrsa -aes256 -passout pass:${ca_private_key_passphrase} -out ${directory}/${ca_name}.key ${key_size} >/dev/null 2>&1
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -passin pass:${ca_private_key_passphrase} -in ${directory}/${ca_name}.key -out ${directory}/${ca_name}.pkcs8.key
openssl req -x509 -new -nodes -passin pass:${ca_private_key_passphrase} -key ${directory}/${ca_name}.key -sha256 -days ${ca_cert_days} -out ${directory}/${ca_name}.crt -subj "/CN=${CN}/C=${C}/ST=${ST}/L=${L}/O=${O}" >/dev/null 2>&1
#
# App certificates creation
#
name="app_cert"
cn="My App"
c="FR"
st="Paris"
l="Paris"
org="MyOrganisation"
dns="myserver1.local"
ip="192.168.1.1"
openssl req -new -nodes -out ${directory}/${name}.csr -newkey rsa:4096 -keyout ${directory}/${name}.key -subj "/CN=${cn}/C=${c}/ST=${st}/L=${l}/O=${org}" >/dev/null 2>&1
echo 'authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
' | tee ${directory}/${name}.v3.ext >/dev/null 2>&1
echo "DNS.1 = ${dns}" | tee -a ${directory}/${name}.v3.ext >/dev/null 2>&1
echo "IP.1 = ${ip}" | tee -a ${directory}/${name}.v3.ext >/dev/null 2>&1
openssl x509 -req -in ${directory}/${name}.csr -CA ${directory}/${ca_name}.crt -passin pass:${ca_private_key_passphrase} -CAkey ${directory}/${ca_name}.key -CAcreateserial -out ${directory}/${name}.crt -days 730 -sha256 -extfile ${directory}/${name}.v3.ext >/dev/null 2>&1
#
curl https://raw.githubusercontent.com/vmware/alb-sdk/eng/python/avi/sdk/samples/clone_vs.py -o /home/ubuntu/clone_vs.py -s
chmod u+x /home/ubuntu/clone_vs.py