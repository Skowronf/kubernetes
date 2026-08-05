#!/usr/bin/env bash
set -euo pipefail

./scripts/build.sh
./scripts/update-docker-image.sh
./scripts/cluster.sh
./scripts/install-cilium.sh
./scripts/create-registry-credentials.sh
./scripts/observability/install.sh
./scripts/create-local-ca-secret.sh
./scripts/smoke-test.sh
./scripts/e2e.sh

echo "Done"
