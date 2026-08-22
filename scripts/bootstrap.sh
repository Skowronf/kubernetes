#!/usr/bin/env bash
set -euo pipefail

./scripts/cluster.sh
./scripts/install-cilium.sh
./scripts/create-registry-credentials.sh
./scripts/observability/install.sh
./scripts/smoke-test.sh
# ./scripts/e2e.sh

echo "Done"
