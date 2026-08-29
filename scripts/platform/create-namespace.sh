#!/usr/bin/env bash

set -euo pipefail

echo "Creating petclinic namespace"
kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -
