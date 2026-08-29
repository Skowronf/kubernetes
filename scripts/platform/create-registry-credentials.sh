#!/bin/bash

set -euo pipefail


echo "Creating GHCR image pull secret in petclinic namespace"

# GHCR_TOKEN must be provided through the environment.
kubectl create secret docker-registry ghcr-secret \
  --namespace petclinic \
  --docker-server=ghcr.io \
  --docker-username="$GHCR_USERNAME" \
  --docker-password="$GHCR_TOKEN" \
  --dry-run=client \
  -o yaml | 
  kubectl apply -f -

echo "GHCR image pull secret created successfully"