#!/usr/bin/env bash

set -euo pipefail

HEALTHY=0
KUBE_AVAILABLE=0
CLUSTER_AVAILABLE=0

# Project directory
if [ -d "$HOME/kubernetes" ]; then
    echo "OK: Kubernetes directory exists"
else
    echo "FAIL: Kubernetes directory does not exist"
    HEALTHY=1
fi

# kubectl availability
if command -v kubectl >/dev/null 2>&1; then
    echo "OK: kubectl is available"
else
    echo "FAIL: kubectl is not available"
    KUBE_AVAILABLE=1
    HEALTHY=1
fi

# Kubernetes cluster
if [ "$KUBE_AVAILABLE" -eq 0 ]; then

    if kubectl cluster-info >/dev/null 2>&1; then
        echo "OK: Kubernetes cluster is available"
    else
        echo "FAIL: Kubernetes cluster is not available"
        CLUSTER_AVAILABLE=1
        HEALTHY=1
    fi

else
    echo "SKIP: Kubernetes cluster check"
fi

# Kubernetes namespaces
if [ "$KUBE_AVAILABLE" -eq 0 ] && [ "$CLUSTER_AVAILABLE" -eq 0 ]; then

    if kubectl get namespace petclinic >/dev/null 2>&1; then
        echo "OK: petclinic namespace exists"
    else
        echo "FAIL: petclinic namespace does not exist"
        HEALTHY=1
    fi

else
    echo "SKIP: Kubernetes namespace checks"
fi

# Final result
if [ "$HEALTHY" -eq 0 ]; then
    echo "HEALTH CHECK: PASS"
    exit 0
else
    echo "HEALTH CHECK: FAIL"
    exit 1
fi