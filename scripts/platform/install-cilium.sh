#!/usr/bin/env bash

set -euo pipefail

echo "Installing Cilium with kube-proxy replacement enabled" 
cilium install \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=127.0.0.1 \
  --set k8sServicePort=6443


echo "Waiting for Cilium to be ready"
cilium status --wait
