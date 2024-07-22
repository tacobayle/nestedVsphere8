#!/bin/bash
jsonFile=$1
/bin/bash /home/ubuntu/lbaas/govc/backend.sh ${jsonFile} &
/bin/bash /home/ubuntu/lbaas/nsx/nsx_group.sh ${jsonFile}
/bin/bash /home/ubuntu/lbaas/avi/vs.sh ${jsonFile}
