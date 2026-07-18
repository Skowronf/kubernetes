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
