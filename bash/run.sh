# vsphere
## destroy
d=vsphere
kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml
## create
d=vsphere ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# vsphere-alb
## destroy
d=vsphere-alb
kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml
## create
d=vsphere-alb ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# vsphere-tanzu-alb-wo-nsx
## destroy
d=vsphere-tanzu-alb-wo-nsx
kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml
## create
d=vsphere-tanzu-alb-wo-nsx ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# vsphere-nsx
## destroy
d=vsphere-nsx
kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml
## create
d=vsphere-nsx ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# vsphere-nsx-alb
## destroy
d=vsphere-nsx-alb
kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml
## create
d=vsphere-nsx-alb ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# vsphere-nsx-alb-telco
## destroy
d=vsphere-nsx-alb-telco
kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml
## create
d=vsphere-nsx-alb-telco ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# python3 -m http.server

python3 -m http.server