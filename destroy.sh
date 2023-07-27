#!/bin/bash
#
# Destroy of a folder on the underlay infrastructure
#
/bin/bash /nestedVsphere8/03_nested_vsphere/destroy.sh
/bin/bash /nestedVsphere8/02_external_gateway/destroy.sh
/bin/bash /nestedVsphere8/01_underlay_vsphere_directory/destroy.sh
cd /
rm -fr nestedVsphere8
git clone https://github.com/tacobayle/nestedVsphere8
# git clone https://github.com/tacobayle/nestedVsphere8 -b dual_attached