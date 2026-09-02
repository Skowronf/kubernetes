#!/usr/bin/env bash

set -euo pipefail

echo "Applying Argo CD Applications to kind cluster"

kubectl apply \
  -f gitops/kind/

echo "Argo CD Applications applied"