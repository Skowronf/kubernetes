#!/usr/bin/env bash

set -euo pipefail

echo "Creating local CA secret"

CAROOT=$(mkcert -CAROOT)

kubectl create secret tls local-ca-keypair \
  --namespace cert-manager \
  --cert="${CAROOT}/rootCA.pem" \
  --key="${CAROOT}/rootCA-key.pem" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

echo "Local CA secret created"