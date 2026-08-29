#!/usr/bin/env bash
set -euo pipefail

echo "=== Platform bootstrap ==="

./scripts/platform/cluster.sh
./scripts/platform/install-cilium.sh
./scripts/platform/create-registry-credentials.sh
./scripts/platform/install-argocd.sh
./scripts/platform/configure-argocd.sh
./scripts/platform/bootstrap-certificates.sh
./scripts/platform/create-local-ca-secret.sh

echo "=== GitOps bootstrap ==="

./scripts/gitops/bootstrap.sh

echo "=== Verification ==="

./scripts/gitops/verify.sh

echo "=== Application tests ==="

./scripts/tests/smoke-test.sh

echo "Bootstrap completed successfully"

