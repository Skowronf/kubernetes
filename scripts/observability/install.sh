#!/usr/bin/env bash

set -euo pipefail

echo "Creating argocd namespace"

kubectl create namespace argocd \
  --dry-run=client -o yaml | kubectl apply -f -

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
  --timeout=280s

echo "Patching Argo CD to allow insecure connections"
kubectl patch deployment argocd-server -n argocd --type=json -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'

echo "Creating Argo CD ingress"

kubectl apply -f bootstrap/argocd/argocd-ingress.yml

echo "Argo CD admin password:"

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

echo "Applying ArgoCD Applications"

kubectl apply -f gitops/argocd/applications/

echo "Waiting for cert-manager namespace"

until kubectl get namespace cert-manager >/dev/null 2>&1; do
  sleep 5
done

./scripts/create-local-ca-secret.sh


echo "Waiting for applications to be healthy in argo"

kubectl wait \
  -n argocd  \
  --for=jsonpath='{.status.health.status}'=Healthy \
  application --all \
  --timeout=2200s