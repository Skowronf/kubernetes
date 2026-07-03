#!/usr/bin/env bash
# its a script to be run with bash

set -euo pipefail
# if any commend end with error, pipeline also fails

echo "Adding Prometheus Helm repo"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "Creating namespace: observability"
# create namespace yaml observability locally (do not sent to cluster), show me yaml, then apply
# using, kubectl create namespace observability,  might get error if namespace already exists
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

echo "Installing kube-prometheus-stack"
# install release or update if it does not exist and wait until its ready
helm upgrade --install prometheus \
  prometheus-community/kube-prometheus-stack \
  -n observability \
  -f k8s/observability/prometheus-values.yml \
  --wait

echo "Prometheus Port forwarding 9090:9090"
# create a local tunnel from localhost:9090 to the prometheus service running inside cluster
kubectl port-forward \
  -n observability \
  svc/prometheus-kube-prometheus-prometheus \
  9090:9090 >/dev/null 2>&1 &

PROM_PID=$!

echo "Adding grafana Helm repo"
helm repo add grafana https://grafana.github.io/helm-charts

echo "Installing grafana in observability namespace"
helm install grafana grafana/grafana \
  --namespace observability \
  -f k8s/observability/grafana-monitor.yml

echo "Starting Grafana port-forward..."
kubectl port-forward \
  -n observability \
  svc/grafana \
  3000:80 >/dev/null 2>&1 &

GRAFANA_PID=$!

wait
