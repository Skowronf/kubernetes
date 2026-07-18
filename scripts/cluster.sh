source ./scripts/env.sh

kind delete cluster --name petclinic-ci || true
kind create cluster --name petclinic-ci
kind load docker-image petclinic:ci --name petclinic-ci

#kind create cluster --name petclinic-ci --config bootstrap/kind/cluster.yml
