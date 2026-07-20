#!/usr/bin/env bash

set -euo pipefail

echo "Creating argocd namespace"

kubectl create namespace argocd

echo "Installing Argo CD"

kubectl apply \
  --server-side \
  -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD"

kubectl wait \
  --for=condition=available \
  deployment/argocd-server \
  -n argocd \
  --timeout=180s

echo "Argo CD admin password:"

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

echo "Applying applications"

kubectl apply -f gitops/applications/

echo "Waiting for Argo Applications to appear (might want to add exit condition)"

until kubectl get applications -n argocd --no-headers 2>/dev/null | grep -q .; do
  sleep 2
done

echo "Waiting for applications to be sync with argo"

kubectl wait \
  -n argocd   \
  --for=jsonpath='{.status.sync.status}'=Synced \
  application --all \
  --timeout=800s

echo "Waiting for applications to be healthy in argo"

kubectl wait \
  -n argocd  \
  --for=jsonpath='{.status.health.status}'=Healthy \
  application --all \
  --timeout=800s
