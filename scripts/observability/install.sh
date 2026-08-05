#!/usr/bin/env bash

set -euo pipefail

echo "Creating argocd namespace"

kubectl create namespace argocd

echo "Installing Argo CD"

kubectl apply \
  --server-side \
  -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.4.6/manifests/install.yaml

echo "Waiting for Argo CD"

kubectl wait \
  --for=condition=available \
  deployment/argocd-server \
  -n argocd \
  --timeout=180s

echo "Patching Argo CD to allow insecure connections"
kubectl patch deployment argocd-server -n argocd --type=json -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'

echo "Creating Argo CD ingress"

kubectl apply -f bootstrap/kind/argocd-ingress.yml

echo "Argo CD admin password:"

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

echo "Applying applications"

echo "Applying ArgoCD Applications"

kubectl apply -f gitops/applications/cert-manager.yml
kubectl apply -f gitops/applications/argo-rollouts.yml
kubectl apply -f gitops/applications/observability.yml
kubectl apply -f gitops/applications/petclinic.yml
kubectl apply -f gitops/applications/ingress-nginx.yml

echo "Waiting for cert-manager CRDs"

until kubectl get crd certificates.cert-manager.io >/dev/null 2>&1; do
  sleep 5
done

kubectl wait \
  --for=condition=Established \
  crd/certificates.cert-manager.io \
  --timeout=120s

kubectl wait \
  --for=condition=Established \
  crd/clusterissuers.cert-manager.io \
  --timeout=120s

until kubectl get deployment cert-manager-webhook -n cert-manager >/dev/null 2>&1; do
  echo "Waiting for cert-manager-webhook Deployment..."
  sleep 2
done

kubectl rollout status deployment cert-manager \
  -n cert-manager \
  --timeout=180s

kubectl rollout status deployment cert-manager-cainjector \
  -n cert-manager \
  --timeout=180s

kubectl rollout status deployment cert-manager-webhook \
  -n cert-manager \
  --timeout=180s

echo "Waiting for cert-manager webhook CA injection"

until kubectl get validatingwebhookconfiguration cert-manager-webhook \
  -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | grep -q .; do
  sleep 5
done

echo "Applying cert-manager resources"

until kubectl apply -f gitops/applications/cluster-issuer.yml; do
  echo "Waiting for cert-manager webhook..."
  sleep 5
done

until kubectl apply -f gitops/applications/argo-certificate.yml; do
  echo "Waiting for cert-manager webhook..."
  sleep 5
done

until kubectl apply -f gitops/applications/petclinic-certificate.yml; do
  echo "Waiting for cert-manager webhook..."
  sleep 5
done


echo "Waiting for Argo Applications to appear (might want to add exit condition)"

until kubectl get applications -n argocd --no-headers 2>/dev/null | grep -q .; do
  sleep 2
done


echo "Waiting for applications to be healthy in argo"

kubectl wait \
  -n argocd  \
  --for=jsonpath='{.status.health.status}'=Healthy \
  application --all \
  --timeout=1200s
