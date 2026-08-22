#!/usr/bin/env bash

set -euo pipefail

readonly ARGOCD_NAMESPACE="argocd"
readonly ARGOCD_APPS_TIMEOUT="2200s"

echo "Waiting for applications to be healthy in Argo CD"

kubectl wait \
  -n "$ARGOCD_NAMESPACE" \
  --for=jsonpath='{.status.health.status}'=Healthy \
  application --all \
  --timeout="$ARGOCD_APPS_TIMEOUT"

echo "All Argo CD Applications are Healthy"