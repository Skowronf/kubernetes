#!/bin/bash

set -e

CLUSTER_NAME="petclinic-ci"

kind delete cluster \
  --name "$CLUSTER_NAME" || true
# |true:
#   Ensures that the script continues even if the cluster delete command fails 

kind create cluster \
  --name "$CLUSTER_NAME" \
  --config bootstrap/kind/cluster.yml
# script must be run from the root of the repository, otherwise kind will not find the config file.