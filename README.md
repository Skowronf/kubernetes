#  Enterprise Platform (Spring PetClinic)

A cloud-native **Platform Engineering + DevSecOps + GitOps showcase project** built on top of the Spring PetClinic application.

This project demonstrates how a simple Spring Boot monolith can evolve into a **production-like Kubernetes platform** with observability, automation, and GitOps principles.

---

##  Architecture Overview

This platform simulates a real-world internal developer platform:

- **Application Layer** → Spring PetClinic
- **Platform Layer** → Kubernetes + Helm
- **Delivery Layer** → GitOps (ArgoCD)
- **Observability Layer** → Prometheus + Grafana + Loki #TODO
- **Automation Layer** → Bash scripts + CI/CD ready structure #TODO

---


##  Key Features

##  Architecture Decisions

All major design decisions are documented in ADR format:

- Kubernetes vs VM deployment
- Helm chart structure
- GitOps approach (ArgoCD)
- Observability stack selection

### Platform Engineering
- Kubernetes-native deployment model
- Helm-based application packaging
- Separation of application and platform concerns

### GitOps (ArgoCD)
- Declarative cluster state
- Version-controlled deployments
- Automated reconciliation of infrastructure

### Observability Stack
- Metrics → Prometheus
- Dashboards → Grafana
- Logs → Loki #TODO

##  Observability Flow

This platform implements observability:

Metrics → Prometheus → Grafana  
Logs → Loki → Grafana  #TODO

## Environments #TODO

The platform supports multi-environment setup: #TODO

- dev
- staging
- production (planned)

Each environment can have:
- different Helm values
- separate ArgoCD apps


### DevSecOps Ready (extensible)
- Kubernetes-native configuration (ConfigMaps & Secrets)
- ADR-driven architecture decisions
- Ready for security scanning & policy-as-code

## CI/CD Pipeline #TODO

This project is designed to be CI/CD-ready. #TODO

### Typical flow:
1. Build application
2. Build Docker image
3. Scan image (security)
4. Deploy via GitOps (ArgoCD)

---

##  Deployment Flow

### 1. Bootstrap environment

```bash
./scripts/bootstrap.sh
```


# Debugging Cheat Sheet (Kubernetes / GitOps / Observability)

This section contains essential commands for debugging issues in a Kubernetes-based platform with GitOps (ArgoCD), Helm, and observability stack (Prometheus, Grafana, Loki).

---

# Kubernetes Debugging

## Cluster overview
```bash
kubectl cluster-info # Shows Kubernetes control plane endpoints
kubectl get nodes -o wide # Lists all nodes with detailed info (IP, status, version)
kubectl get namespaces # Shows all namespaces in the cluster
```

---

## Workloads overview
```bash
kubectl get pods -A # Lists all pods in all namespaces
kubectl get deployments -A # Lists all deployments in all namespaces
kubectl get services -A # Lists all services in all namespaces
kubectl get ingress -A # Lists all ingress resources in all namespaces
```

---

## Inspecting resources
```bash
kubectl describe pod <pod-name> -n <namespace> # Shows detailed info about a pod (events, errors, config)
kubectl describe deployment <deployment-name> -n <namespace> # Shows deployment configuration and rollout status
kubectl get events -A --sort-by=.metadata.creationTimestamp # Shows cluster events sorted by time
kubectl exec -it <pod> -- /bin/sh # Opens a shell inside the container
kubectl exec -it <postgres-pod-name> -- psql -U postgres # Opens PostgreSQL CLI directly inside the database container
```

---

## Logs
```bash
kubectl logs <pod-name> # Shows logs from a pod
kubectl logs -f <pod-name> # Streams logs in real-time (follow mode)
kubectl logs <pod-name> -c <container-name> # Shows logs from a specific container inside a pod
kubectl logs <pod-name> --previous # Shows logs from the previous container instance (after crash)
```

---

## Helm debugging
```bash
helm upgrade petclinic ./charts/petclinic  # Upgrades or installs the Helm release for PetClinic
helm list -A # Lists all Helm releases in all namespaces
helm status <release> # Shows status of a Helm release
helm get all <release> # Displays full information about a release (manifests, values)**
helm template <chart> # Renders Kubernetes manifests locally without installing
helm lint <chart> # Validates Helm chart for syntax and best practices
```


