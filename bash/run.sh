kubectl delete pod test-pod1
kubectl delete configmap configmap1
kubectl apply -f configmap1-nested-vpshere.yml
kubectl apply -f pod1-nested-vpshere.yml
sleep 5
kubectl exec -it test-pod1 -- /bin/bash

/bin/bash nestedVsphere8/apply.sh
---
kubectl delete pod test-pod2
kubectl delete configmap configmap2
kubectl apply -f configmap2-nested-vpshere-nsx.yml
kubectl apply -f pod2-nested-vpshere-nsx.yml
sleep 5
kubectl exec -it test-pod2 -- /bin/bash

/bin/bash nestedVsphere8/apply.sh
