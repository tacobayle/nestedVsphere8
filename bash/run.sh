# vsphere
## destroy
d=vsphere
kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0
## create
d=vsphere ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# vsphere-alb
## destroy
d=vsphere-alb ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
d=vsphere-alb ; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0
## create
d=vsphere-alb ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh
## destroy - create
d=vsphere-alb ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh ; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0 ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# vsphere-tanzu-alb-wo-nsx
## destroy
d=vsphere-tanzu-alb-wo-nsx ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
d=vsphere-tanzu-alb-wo-nsx ; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0
## create
d=vsphere-tanzu-alb-wo-nsx ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh
## destroy - create
d=vsphere-tanzu-alb-wo-nsx ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh ; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0 ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh



# vsphere-nsx
## destroy
d=vsphere-nsx
d=vsphere-nsx ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
d=vsphere-nsx ; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0
## create
d=vsphere-nsx ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# vsphere-nsx-tanzu-alb
## destroy
d=vsphere-nsx-tanzu-alb ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
d=vsphere-nsx-tanzu-alb ; kubectl delete -f secrets-${d}.yml ; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0 ;
## create
d=vsphere-nsx-tanzu-alb ; ./update_password.sh secrets-${d}.yml ; kubectl apply -f secrets-${d}.yml ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh
d=vsphere-nsx-tanzu-alb ; curl https://raw.githubusercontent.com/tacobayle/k8sYaml/master/nestedVsphere8/cm-template.yml ; sed -e "s/\${d}/${d}/" cm-template.yml | tee cm-${d}.yml ; echo "" | tee -a cm-${d}.yml ; yq . ${d}.yml | sed  's/^/    /' | tee -a cm-${d}.yml ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh
## destroy - create
d=vsphere-nsx-tanzu-alb ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh ; kubectl delete -f secrets-${d}.yml ; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0 ; ./update_password.sh secrets-${d}.yml ; kubectl apply -f secrets-${d}.yml ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# vsphere-nsx-alb
## destroy
d=vsphere-nsx-alb ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
d=vsphere-nsx-alb; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0
## create
d=vsphere-nsx-alb ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh
## destroy - create
d=vsphere-nsx-alb ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh ; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0 ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# test
## destroy
d=test ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
d=test ; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0
## create
d=test ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/00_pre_check/00.sh
## destroy - create
d=test ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh ; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0 ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh


# vsphere-nsx-alb
## destroy
d=vsphere-nsx-alb ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh
d=vsphere-nsx-alb; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0
## create
d=vsphere-nsx-alb ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh
## destroy - create
d=vsphere-nsx-alb ; kubectl exec -it pod-${d} -- nestedVsphere8/destroy.sh ; kubectl delete -f cm-${d}.yml ; kubectl delete -f pod-${d}.yml --grace-period=0 ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh

# python3 -m http.server

python3 -m http.server

# Archives
d=vsphere-nsx-alb-telco ; kubectl apply -f cm-${d}.yml ; kubectl apply -f pod-${d}.yml ; sleep 5 ; kubectl exec -it pod-${d} -- /bin/bash -c "rm -fr nestedVsphere8 ; git clone https://github.com/tacobayle/nestedVsphere8 -b dual_attached"; kubectl exec -it pod-${d} -- nestedVsphere8/apply.sh
