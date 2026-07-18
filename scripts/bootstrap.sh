#!/usr/bin/env bash
set -euo pipefail

./scripts/build.sh
./scripts/cluster.sh
./scripts/observability/install.sh
./scripts/smoke-test.sh
./scripts/e2e.sh

echo "Done"
