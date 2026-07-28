#!/bin/bash

set -e


echo "Creating GHCR image pull secret"

kubectl create secret docker-registry ghcr-secret \
  --namespace petclinic \
  --docker-server=ghcr.io \
  --docker-username=skowronf \
  --docker-password="$GHCR_TOKEN" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

echo "GHCR secret created"