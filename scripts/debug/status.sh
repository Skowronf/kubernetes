#!/usr/bin/env bash
set -euo pipefail

KUBE_AVAILABLE=0
HEALTHY=0

# kubectl availability
if command -v kubectl >/dev/null 2>&1; then
    echo "OK: kubectl is available"
else
    echo "FAIL: kubectl is not available"
    KUBE_AVAILABLE=1
    HEALTHY=1
fi

if [ "$KUBE_AVAILABLE" -eq 0 ]; then

    # Pods
    echo
    echo "=== Petclinic namespace ==="

    if kubectl get pods -n petclinic --no-headers |
        awk '{
            split($2, ready, "/")

            if (($3 == "Running" && ready[1] == ready[2]) || $3 == "Completed") {
                print "OK:", $1, "READY:", $2, "STATUS:", $3
            } else {
                print "FAIL:", $1, "READY:", $2, "STATUS:", $3
                bad=1
            }
        }
        END {
            exit bad
        }'
    then
        echo "OK: Kubernetes petclinic namespace info retrieved successfully"
    else
        HEALTHY=1
        echo "FAIL: Kubernetes petclinic namespace info cannot be retrieved"
    fi

    # Rollout
    echo
    echo "=== Rollout ==="

    if kubectl get rollout -n petclinic; then
        echo "OK: Kubernetes petclinic rollout completed successfully"
    else
        HEALTHY=1
        echo "FAIL: Kubernetes petclinic rollout failed"
    fi

    # Services
    echo
    echo "=== Services ==="

    if kubectl get services -n petclinic -o json | 
    jq -r '
    .items[] |
    [
        .metadata.name,
        .spec.type,
        .spec.clusterIP,
        (.spec.ports[0].port | tostring)
    ] |
    @tsv
    ' |
    column -t; then
        echo "OK: Kubernetes petclinic services retrieved successfully"
    else
        HEALTHY=1
        echo "FAIL: Kubernetes petclinic services cannot be retrieved"
    fi

else
    echo "FAIL: Kubernetes petclinic namespace info cannot be retrieved because kubectl is not available"
fi

exit "$HEALTHY"