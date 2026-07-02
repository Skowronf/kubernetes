#!/usr/bin/env bash
set -euo pipefail

./scripts/build.sh
./scripts/cluster.sh
./scripts/deploy.sh
./scripts/port-forward.sh
./scripts/smoke-test.sh
./scripts/e2e.sh
./scripts/observability/install.sh

echo "Done"
