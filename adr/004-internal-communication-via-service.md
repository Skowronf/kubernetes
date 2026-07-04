# ADR-004: Service Discovery and Internal Communication via Kubernetes Services

## Status
Accepted

---

## Context

The PetClinic application and PostgreSQL database run as separate Pods inside a Kubernetes cluster. Pod IP addresses are ephemeral and can change whenever Pods are restarted, rescheduled, or replaced.

A stable communication mechanism is required to ensure:

- reliable connectivity between PetClinic and PostgreSQL
- decoupling from dynamic Pod IPs
- internal-only access within the cluster
- DNS-based service resolution instead of hardcoded IPs

---

## Decision

Kubernetes `Service` resources of type `ClusterIP` are used to provide internal service discovery:

- `postgres` Service exposes PostgreSQL on port `5432`
- `petclinic` Service exposes the application on port `8080`
- Services use label selectors (`app: postgres`, `app: petclinic`) to target Pods
- Communication between components is performed using Kubernetes DNS names:
    - `postgres.petclinic`
    - `petclinic.petclinic`

---

## Rationale

- Kubernetes Services provide stable virtual IPs and DNS names regardless of Pod lifecycle
- ClusterIP type ensures services are only accessible within the cluster, improving security
- Label selectors decouple Services from specific Pod instances
- DNS-based discovery simplifies configuration in both application and database connectivity
- Aligns with Kubernetes-native networking model and best practices

---

## Consequences

### Positive

- Stable communication independent of Pod restarts or rescheduling
- No need to manage or track Pod IP addresses
- Simple and predictable service-to-service communication
- Improved security due to internal-only exposure (ClusterIP)
- Native Kubernetes DNS resolution simplifies configuration

### Negative

- Services are only reachable inside the cluster (no external access by design)
- Misconfigured labels can break service routing
- No load balancing tuning beyond default Kubernetes behavior

---

## Alternatives Considered

### 1. Direct Pod IP communication
Rejected due to instability and lack of resilience across Pod restarts.

### 2. Headless Services
Rejected as unnecessary for current architecture; stable load-balanced access was sufficient.

### 3. External service mesh (e.g., Istio)
Rejected due to excessive complexity for current learning scope.
