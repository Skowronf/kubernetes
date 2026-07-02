#!/usr/bin/env bash
set -euo pipefail

echo "Adding Prometheus Helm repo"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "Creating namespace: observability"
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

echo "Installing kube-prometheus-stack"
helm upgrade --install prometheus \
  prometheus-community/kube-prometheus-stack \
  -n observability \
  --wait

echo "Prometheus Port forwarding 9090:9090"
kubectl port-forward \
svc/prometheus-kube-prometheus-prometheus \
9090:9090  \
-n observability
