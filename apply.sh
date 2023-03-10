#!/bin/bash
#
echo ""
echo "==> Checking Variables files"
if [ -s "/etc/config/variables.json" ]; then
  jsonFile="/etc/config/variables.json"
  jq . $jsonFile > /dev/null
  jq . $jsonFile
else
  echo "/etc/config/variables.json file is empty!!"
  exit 255
fi
#
/bin/bash /nestedVsphere8/00_pre_check/00.sh
#if [ $? -ne 0 ] ; then exit 1 ; fi
/bin/bash /nestedVsphere8/00_pre_check/01.sh
#if [ $? -ne 0 ] ; then exit 1 ; fi
/bin/bash /nestedVsphere8/00_pre_check/02.sh
#if [ $? -ne 0 ] ; then exit 1 ; fi
/bin/bash /nestedVsphere8/00_pre_check/03.sh
#if [ $? -ne 0 ] ; then exit 1 ; fi
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/04.sh
  # if [ $? -ne 0 ] ; then exit 1 ; fi
  /bin/bash /nestedVsphere8/00_pre_check/05.sh
  # if [ $? -ne 0 ] ; then exit 1 ; fi
  /bin/bash /nestedVsphere8/00_pre_check/06.sh
  # if [ $? -ne 0 ] ; then exit 1 ; fi
fi
if [[ $(jq -c -r .avi $jsonFile) != "null" ]]; then
  /bin/bash /nestedVsphere8/00_pre_check/07.sh
  # if [ $? -ne 0 ] ; then exit 1 ; fi
fi
/bin/bash /nestedVsphere8/01_underlay_vsphere_directory/apply.sh
#if [ $? -ne 0 ] ; then exit 1 ; fi
/bin/bash /nestedVsphere8/02_external_gateway/apply.sh
#if [ $? -ne 0 ] ; then exit 1 ; fi
/bin/bash /nestedVsphere8/03_nested_vsphere/apply.sh
#if [ $? -ne 0 ] ; then exit 1 ; fi
if [[ $(jq -c -r .nsx $jsonFile) != "null" ]]; then
  echo "waiting for 20 minutes to finish the vCenter config..."
  sleep 1200
  /bin/bash /nestedVsphere8/04_nsx_networks/apply.sh
  # if [ $? -ne 0 ] ; then exit 1 ; fi
  /bin/bash /nestedVsphere8/05_nsx_manager/apply.sh
  # if [ $? -ne 0 ] ; then exit 1 ; fi
  echo "waiting for 5 minutes to finish the NSX bootstrap..."
  sleep 300
  /bin/bash /nestedVsphere8/06_nsx_config/apply.sh
  # if [ $? -ne 0 ] ; then exit 1 ; fi
fi
while true ; do sleep 3600 ; done