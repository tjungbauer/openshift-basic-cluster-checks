# Variables
basedomain=ocp.aws.ispworld.at

printf "Starting the check of\n"
oc whoami --show-server
printf "##########################\n"

printf "Get Cluster version~\n"
oc get clusterversion
printf "##########################\n"

printf "Get ClusterOperators\n"
oc get clusteroperators
printf "##########################\n"

printf "Get list of nodes\n"
oc get nodes
printf "##########################\n"

for mcp in $(oc get mcp -o name | awk -F"/" '{print $2}'); do
  printf "Checking Role $mcp\n"
  oc get nodes -l node-role.kubernetes.io/$mcp -o jsonpath='{range.items[*]}{.metadata.name}: {.status.capacity.cpu} CPU(s) | {.status.capacity.memory} Memory{"\n"}{end}'
  printf "##########################\n"
done

printf "TOP of all Nodes\n"
oc adm top nodes
printf "##########################\n"

printf "Check for failing pods\n"
oc get pods -A | egrep -v "Running|Completed"
printf "##########################\n"

printf "Check for Pods in status.phase=Failed\n"
oc get pods --field-selector status.phase=Failed -A
printf "##########################\n"

printf "Get APIServer Pods and check for errors in the logs\n"
oc get pod -n openshift-kube-apiserver -l app=openshift-kube-apiserver

for pod in $(oc get pod -n openshift-kube-apiserver -l app=openshift-kube-apiserver -o custom-columns=POD:.metadata.name --no-headers); do
  printf "Check Pod $pod\n"
  oc logs -n openshift-kube-apiserver $pod; done | egrep -c "^ERROR"
printf "##########################\n"

printf "Get IngressController \n"
for ic in $(oc get ingresscontroller -n openshift-ingress-operator -o name | awk -F"/" '{print $2}'); do
  printf "Check Controller $ic\n"
  oc get ingresscontroller/$ic -n openshift-ingress-operator -o yaml
done
printf "##########################\n"

printf "Check Certificates\n"
printf "Check Ingress (apps) Certificate\n"
curl -kvI https://ssltest.apps.$basedomain 2>&1 | grep -A5 'Server certificate'
printf "##########################\n"
printf "Check API Certificate\n"
curl -kvI https://api.$basedomain:6443 2>&1 | grep -A5 'Server certificate'
printf "##########################\n"

printf "Get Clusternetwork (SDN)\n"
oc get clusternetwork
printf "##########################\n"

printf "Get Hostsubnets (SDN)\n"
oc get hostsubnets
printf "##########################\n"

oc get pods -n openshift-etcd | grep etcd
printf "##########################\n"
for etcd in $(oc get pods -n openshift-etcd -o name | grep etcd | grep -v guard | head -n 1); do
  printf "Using $etcd for checking\n"
  printf "List etcd members\n"
  oc rsh -n openshift-etcd $etcd etcdctl member list -w table
  printf "##########################\n"
  printf "List etcd health\n"
  oc rsh -n openshift-etcd $etcd etcdctl endpoint health --cluster -w table 
  printf "##########################\n"
  printf "Check etcd for alarms\n"
  oc rsh -n openshift-etcd $etcd etcdctl alarm list
  printf "##########################\n"
  printf "Get endpoint status\n"
  oc rsh -n openshift-etcd $etcd etcdctl endpoint status --cluster -w table
  printf "##########################\n"
done

printf "Get node labels\n"
oc get node --show-labels
printf "##########################\n"

printf "Check if control planes are scheduable and scheduler configuration\n"
oc get -o yaml scheduler cluster
printf "##########################\n"

printf "Get MachineConfigPools\n"
oc get mcp
printf "##########################\n"

printf "Get installed operators\n"
oc get subscription -A
printf "##########################\n"

printf "Get APIServer configuration\n"
oc get apiserver cluster -o yaml
printf "##########################\n"

printf "Check kubeapiserver for encryption\n"
oc get kubeapiserver -o=jsonpath='{range .items[0].status.conditions[?(@.type=="Encrypted")]}{.reason}{"\n"}{.message}{"\n"}'
printf "##########################\n"

printf "Check openshiftapiserver for encryption\n"
oc get openshiftapiserver -o=jsonpath='{range .items[0].status.conditions[?(@.type=="Encrypted")]}{.reason}{"\n"}{.message}{"\n"}'
printf "##########################\n"

printf "Get network configuration\n"
oc describe network.config cluster
printf "##########################\n"

printf "Verify ImagePruner Configuration\n"
oc get imagepruner -o yaml
printf "##########################\n"

printf "Get ClusterConfig\n"
oc get config cluster -o yaml
printf "##########################\n"

printf "Verify ETCD Performance\n"
oc get nodes -l node-role.kubernetes.io/master -o name
printf "##########################\n"

printf "Get SCCs\n"
oc get scc
printf "##########################\n"

printf "Get Project Creation Template\n"
oc get project.config.openshift.io/cluster -o yaml
printf "##########################\n"

printf "Verify if self-provisioner is activated\n"
oc describe clusterrolebinding.rbac self-provisioners
printf "##########################\n"

oc get nodes -l node-role.kubernetes.io/master -o name
printf "Now execute the following commands on the nodes: 
sudo podman run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/openshift-scale/etcd-perf"
printf "##########################\n"
