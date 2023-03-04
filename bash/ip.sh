ip_prefix_by_netmask () {
  # $1 netmask
  # $2 indentation message
  error_prefix=1
  if [[ $1 == "255.255.255.255" ]] ; then echo "32" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.255.254" ]] ; then echo "31" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.255.252" ]] ; then echo "30" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.255.248" ]] ; then echo "29" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.255.240" ]] ; then echo "28" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.255.224" ]] ; then echo "27" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.255.192" ]] ; then echo "26" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.255.128" ]] ; then echo "25" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.255.0" ]] ; then echo "24" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.254.0" ]] ; then echo "23" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.252.0" ]] ; then echo "22" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.248.0" ]] ; then echo "21" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.240.0" ]] ; then echo "20" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.224.0" ]] ; then echo "19" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.192.0" ]] ; then echo "18" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.128.0" ]] ; then echo "17" ; error_prefix=0 ; fi
  if [[ $1 == "255.255.0.0" ]] ; then echo "16" ; error_prefix=0 ; fi
  if [[ $1 == "255.254.0.0" ]] ; then echo "15" ; error_prefix=0 ; fi
  if [[ $1 == "255.252.0.0" ]] ; then echo "14" ; error_prefix=0 ; fi
  if [[ $1 == "255.248.0.0" ]] ; then echo "13" ; error_prefix=0 ; fi
  if [[ $1 == "255.240.0.0" ]] ; then echo "12" ; error_prefix=0 ; fi
  if [[ $1 == "255.224.0.0" ]] ; then echo "11" ; error_prefix=0 ; fi
  if [[ $1 == "255.192.0.0" ]] ; then echo "10" ; error_prefix=0 ; fi
  if [[ $1 == "255.128.0.0" ]] ; then echo "9" ; error_prefix=0 ; fi
  if [[ $1 == "255.0.0.0" ]] ; then echo "8" ; error_prefix=0 ; fi
  if [[ $1 == "254.0.0.0" ]] ; then echo "7" ; error_prefix=0 ; fi
  if [[ $1 == "252.0.0.0" ]] ; then echo "6" ; error_prefix=0 ; fi
  if [[ $1 == "248.0.0.0" ]] ; then echo "5" ; error_prefix=0 ; fi
  if [[ $1 == "240.0.0.0" ]] ; then echo "4" ; error_prefix=0 ; fi
  if [[ $1 == "224.0.0.0" ]] ; then echo "3" ; error_prefix=0 ; fi
  if [[ $1 == "192.0.0.0" ]] ; then echo "2" ; error_prefix=0 ; fi
  if [[ $1 == "128.0.0.0" ]] ; then echo "1" ; error_prefix=0 ; fi
  if [[ error_prefix -eq 1 ]] ; then echo "$2+++ $1 does not seem to be a proper netmask" ; fi
   }