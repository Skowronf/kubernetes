source ./scripts/env.sh

echo "Installing Cilium"
cilium install
echo "Waiting for Cilium to be ready"
cilium status --wait
