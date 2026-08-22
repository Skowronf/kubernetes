#!/usr/bin/env bash
set -euo pipefail

./scripts/cluster.sh
./scripts/install-cilium.sh
./scripts/create-registry-credentials.sh
./scripts/install-argocd.sh
./scripts/configure-argocd.sh
./scripts/bootstrap-gitops.sh
./scripts/bootstrap-certificates.sh
./scripts/create-local-ca-secret.sh
./scripts/verify-gitops.sh
#./scripts/observability/install.sh
./scripts/smoke-test.sh

echo "Done"
