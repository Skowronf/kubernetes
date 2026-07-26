source ./scripts/env.sh

echo "Installing Cilium" 
cilium install --set kubeProxyReplacement=true --set k8sServiceHost=127.0.0.1 --set k8sServicePort=6443
echo "Waiting for Cilium to be ready"
cilium status --wait

echo "Creating petclinic namespace"
kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f policy/deny-all.yml