kubectl delete pod test-pod1
kubectl delete configmap configmap1
kubectl apply -f configmap1-nested-vpshere.yml
kubectl apply -f pod1-nested-vpshere.yml
sleep 3
kubectl exec -it test-pod1 -- /bin/bash

/bin/bash nestedVsphere8/apply.sh
---
kubectl delete pod test-pod2
kubectl delete configmap configmap2
kubectl apply -f configmap2-nested-vpshere-nsx.yml
kubectl apply -f pod2-nested-vpshere-nsx.yml
sleep 2
kubectl exec -it test-pod2 -- /bin/bash


/bin/bash nestedVsphere8/apply.sh


jq . /etc/config/variables.json
/bin/bash /nestedVsphere8/00_pre_check/00.sh
/bin/bash /nestedVsphere8/00_pre_check/01.sh
/bin/bash /nestedVsphere8/00_pre_check/02.sh
/bin/bash /nestedVsphere8/00_pre_check/03.sh
/bin/bash /nestedVsphere8/00_pre_check/04.sh
/bin/bash /nestedVsphere8/00_pre_check/05.sh
/bin/bash /nestedVsphere8/00_pre_check/06.sh
