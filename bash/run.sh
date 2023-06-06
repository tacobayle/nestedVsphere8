kubectl delete pod test-pod1
kubectl delete configmap configmap1
kubectl apply -f configmap1-nested-vpshere.yml
kubectl apply -f pod1-nested-vpshere.yml
sleep 3
kubectl exec -it pod1-nested-vsphere -- /bin/bash
/bin/bash nestedVsphere8/apply.sh
/bin/bash nestedVsphere8/destroy.sh



---
kubectl delete pod pod2
kubectl delete configmap configmap2
kubectl apply -f configmap2-nested-vpshere-nsx.yml
kubectl apply -f pod2-nested-vpshere-nsx.yml
sleep 2
kubectl exec -it pod2 -- /bin/bash

/bin/bash nestedVsphere8/apply.sh
cd / ; /bin/bash nestedVsphere8/destroy.sh
cd / ; rm -fr nestedVsphere8 ; git clone https://github.com/tacobayle/nestedVsphere8 ;  /bin/bash /nestedVsphere8/apply.sh

---
kubectl delete pod test-pod3
kubectl delete configmap configmap3
kubectl apply -f configmap3-nested-vsphere-nsx-alb.yml
kubectl apply -f pod3-nested-vsphere-nsx-alb.yml
sleep 3
kubectl exec -it test-pod3 -- /bin/bash

/bin/bash nestedVsphere8/apply.sh
/bin/bash nestedVsphere8/destroy.sh

---

kubectl delete pod test-pod4
kubectl delete configmap configmap4
kubectl apply -f configmap4-nested-vsphere-nsx-alb-vcd.yml
kubectl apply -f pod4-nested-vsphere-nsx-alb-vcd.yml
sleep 3
kubectl exec -it test-pod4 -- /bin/bash

/bin/bash nestedVsphere8/apply.sh
/bin/bash nestedVsphere8/destroy.sh



# python3 -m http.server

python3 -m http.server