#!/bin/bash
set -e

export IMAGE_NAME="petclinic:ci"
export TAG="sha-local"

echo "Cleaning old cluster"
kind delete cluster --name petclinic-ci || true

echo "Building backend"
mvn clean package -DskipTests

echo "Building Docker image"
docker build -t petclinic:ci .

echo "rivy scan"
trivy image petclinic:ci --severity CRITICAL || exit 1

echo "☸creating kind cluster"
kind create cluster --name petclinic-ci

echo "Loading image into kind"
kind load docker-image petclinic:ci --name petclinic-ci

echo "Injecting image tag"
sed -i "s|REPLACE_ME|ci|g" k8s/petclinic.yml

echo "Deploying to Kubernetes"
kubectl create namespace petclinic || true
kubectl apply -n petclinic -f k8s/

echo "Waiting for rollout"
kubectl rollout status deployment/petclinic -n petclinic --timeout=180s

echo "Port-forward"
kubectl port-forward svc/petclinic -n petclinic 8080:8080 &
PF_PID=$!

sleep 5

echo "Smoke test"
curl -f http://localhost:8080

echo "Running Playwright tests"
cd ui-tests
npm ci
npx playwright install --with-deps
npx playwright test --shard=1/3
npx playwright test --shard=2/3
npx playwright test --shard=3/3

kill $PF_PID || true

echo "Prometheus Port forwarding 9090:9090"
kubectl port-forward \
svc/prometheus-kube-prometheus-prometheus \
9090:9090 \
-n observability

echo "✅ DONE"
