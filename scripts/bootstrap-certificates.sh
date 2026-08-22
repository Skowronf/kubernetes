#!/usr/bin/env bash

set -euo pipefail

echo "Waiting for cert-manager namespace"

until kubectl get namespace cert-manager >/dev/null 2>&1; do
  sleep 5
done
