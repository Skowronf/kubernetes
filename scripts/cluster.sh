#!/bin/bash

set -e

CLUSTER_NAME="petclinic-ci"

kind delete cluster \
  --name ${CLUSTER_NAME} || true
# |true:
#   Ensures that the script continues even if the cluster does not exist.

kind create cluster \
  --name ${CLUSTER_NAME} \
  --config bootstrap/kind/cluster.yml