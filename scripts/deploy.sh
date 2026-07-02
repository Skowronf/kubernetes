source ./scripts/env.sh

kubectl apply -n petclinic -f k8s/
kubectl rollout status deployment/petclinic -n petclinic --timeout=180s
