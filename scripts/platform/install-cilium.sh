#!/usr/bin/env bash

set -euo pipefail

echo "Installing Cilium with kube-proxy replacement enabled" 
cilium install \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=127.0.0.1 \
  --set k8sServicePort=6443


echo "Waiting for Cilium to be ready"
cilium status --wait


echo "Creating petclinic namespace"
kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -


echo "Applying default deny NetworkPolicy"
kubectl apply -f policy/deny-all.yml