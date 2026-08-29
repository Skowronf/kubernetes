#!/usr/bin/env bash
set -euo pipefail

echo "=== Platform bootstrap ==="

./scripts/platform/cluster.sh
./scripts/platform/install-cilium.sh
./scripts/platform/install-argocd.sh
./scripts/platform/configure-argocd.sh


echo "=== ArgoCD prerequisites  ==="

./scripts/platform/create-namespace.sh
./scripts/platform/create-registry-credentials.sh


echo "=== GitOps bootstrap ==="

./scripts/gitops/bootstrap.sh


echo "=== Local CA ==="

./scripts/platform/wait-for-cert-manager.sh
./scripts/platform/create-local-ca-secret.sh


echo "=== Verification ==="

./scripts/gitops/verify.sh


echo "=== Application tests ==="

./scripts/tests/smoke-test.sh


echo "Bootstrap completed successfully"
