# ADR-002: PetClinic Application Deployment Design on Kubernetes

## Status
Accepted

---

## Context

The PetClinic application is a Spring Boot service that needs to run inside a Kubernetes cluster.

The system requires:

- controlled rollout and lifecycle management of the application
- stable labeling for service discovery
- controlled startup behavior to avoid routing traffic to unready pods
- simplified local development workflow (no external container registry)
- basic HTTP-based readiness validation

A Kubernetes-native deployment strategy is needed to manage the application lifecycle.

---

## Decision

The PetClinic application is deployed using a Kubernetes `Deployment` resource with the following characteristics:

- 1 replica
- label selector `app: petclinic`
- container image: `petclinic:ci`
- `imagePullPolicy: Never` (local image usage)
- container port: `8080`
- HTTP readiness probe on `/`
- environment variables injected via `ConfigMap`

---

## Rationale

- `Deployment` provides declarative lifecycle management and self-healing capabilities
- Label-based selection ensures stable service discovery via Kubernetes Services
- Single replica simplifies initial setup and debugging
- Local image usage speeds up development iteration without registry dependency
- Readiness probe ensures traffic is only routed to fully initialized application instances
- Externalized configuration via `ConfigMap` avoids hardcoding environment-specific values

---

## Consequences

### Positive

- Application automatically restarts on failure (self-healing)
- Safe traffic routing via readiness probe
- Clear separation between application logic and configuration
- Simple development workflow with local images
- Stable service discovery via consistent labels

### Negative

- Single replica limits availability and scalability
- Local image usage reduces portability across environments
- No rolling update strategy tuning (default Kubernetes behavior only)
- No autoscaling (HPA not implemented)

---

## Alternatives Considered

### 1. Kubernetes Pod (no Deployment)
Rejected due to lack of self-healing and lifecycle management.

### 2. StatefulSet
Rejected as PetClinic is stateless and does not require stable identity or persistent storage (Added later).

### 3. External container registry usage
Rejected to simplify local development and avoid CI/CD dependency at this stage.
