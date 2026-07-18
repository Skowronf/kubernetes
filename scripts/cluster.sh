source ./scripts/env.sh

kind delete cluster --name petclinic-ci || true
kind create cluster --name petclinic-ci --config bootstrap/kind/cluster.yml
kind load docker-image petclinic:ci --name petclinic-ci
