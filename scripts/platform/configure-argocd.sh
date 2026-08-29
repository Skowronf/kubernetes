#!/usr/bin/env bash

set -euo pipefail

readonly ARGOCD_NAMESPACE="argocd"

echo "Configuring Argo CD for insecure connections"

kubectl patch deployment argocd-server \
  -n "$ARGOCD_NAMESPACE" \
  --type=json \
  -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/args/-",
      "value": "--insecure"
    }
  ]'

echo "Waiting for Argo CD configuration rollout"

kubectl rollout status \
  deployment/argocd-server \
  -n "$ARGOCD_NAMESPACE" \
  --timeout=280s

echo "Creating Argo CD ingress"

kubectl apply \
  -f bootstrap/argocd/argocd-ingress.yml

echo "Argo CD configuration completed"

echo "Argo CD admin password:"

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
