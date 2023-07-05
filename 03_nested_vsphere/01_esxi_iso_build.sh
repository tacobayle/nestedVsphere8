#!/bin/bash
#
jsonFile="/root/nested_vsphere.json"
#
iso_mount_location="/tmp/esxi_cdrom_mount"
iso_build_location="/tmp/esxi_cdrom"
iso_source_location=$(jq -r .iso_source_location $jsonFile)
boot_cfg_location=$(jq -r .boot_cfg_location $jsonFile)
iso_location=$(jq -r .iso_location $jsonFile)
count=$(jq -c -r '.vsphere_underlay.networks.vsphere.management.esxi_ips | length' $jsonFile)
#
echo ""
xorriso -ecma119_map lowercase -osirrox on -indev $iso_source_location -extract / $iso_mount_location
echo "++++++++++++++++++++++++++++++++"
echo "Copying source ESXi ISO to Build directory"
rm -fr $iso_build_location
mkdir -p $iso_build_location
cp -r $iso_mount_location/* $iso_build_location
#
echo ""
rm -fr $iso_mount_location
#
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Modifying $iso_build_location/$boot_cfg_location"
IFS=$'\n'
for line in $(jq -r .boot_cfg_lines[] $jsonFile)
do
  echo $line | tee -a $iso_build_location/$boot_cfg_location
done
#
for esx in $(seq 0 $(expr $count - 1))
do
echo ""
echo "++++++++++++++++++++++++++++++++"
echo "Building custom ESXi ISO for ESXi$esx"
  rm -f $iso_location$esx.iso
  rm -f $iso_build_location/ks_cust.cfg
  echo ""
  echo "+++++++++++++++++++"
  echo "Copying ks_cust.cfg"
  cp /root/ks_cust.cfg.$esx $iso_build_location/ks_cust.cfg
  echo ""
  echo "+++++++++++++++++++"
  echo "Building new ISO"
  genisoimage -relaxed-filenames -J -R -o $iso_location$esx.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -eltorito-alt-boot -e efiboot.img -no-emul-boot $iso_build_location
  echo "+++++++++++++++++++"
done
#