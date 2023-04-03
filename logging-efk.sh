#/bin/bash

oc adm top nodes
printf "##########################\n"

# EFK STACK
oc project openshift-logging
printf "##########################\n"

oc get clusterlogging instance -o yaml
printf "##########################\n"

oc get ClusterLogForwarder -o yaml
printf "##########################\n"

oc describe deployment cluster-logging-operator
printf "##########################\n"

oc get replicaset
printf "##########################\n"

for pod in $(oc get pods --selector component=elasticsearch -n openshift-logging -o name); do
  printf "Check Pod $pod\n"
  oc exec -n openshift-logging $pod -- indices;
done
printf "##########################\n"
