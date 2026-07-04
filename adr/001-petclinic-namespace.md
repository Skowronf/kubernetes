# ADR-001: Kubernetes Namespace Isolation for PetClinic

## Status
Accepted

---

## Context

The PetClinic application and its supporting services (PostgreSQL, configuration, secrets) are deployed into a Kubernetes cluster.

Without logical separation, all resources would live in the default namespace, which increases the risk of:

- resource name collisions
- reduced clarity in cluster organization
- harder lifecycle management (cleanup, scaling, debugging)
- limited readiness for multi-environment setups

A mechanism is needed to logically isolate all PetClinic-related resources.

---

## Decision

A dedicated Kubernetes namespace `petclinic` is introduced and used for all application resources.

All Kubernetes objects (Deployments, Services, Secrets, PVCs) related to the system are deployed exclusively within this namespace.

---

## Rationale

- Provides logical separation of workloads within the same cluster
- Prevents naming conflicts with other applications
- Simplifies kubectl operations (scoped queries and debugging)
- Enables future expansion to multiple environments (e.g. `petclinic-dev`, `petclinic-prod`)
- Aligns with Kubernetes best practices for multi-tenant clusters

---

## Consequences

### Positive

- Clear isolation of all PetClinic resources
- Easier management and troubleshooting
- Safer experimentation without affecting other workloads
- Foundation for environment-based deployment strategy

### Negative

- Requires explicit `namespace` specification in all manifests
- Slightly more configuration overhead per resource

---

## Alternatives Considered

### 1. Using the default namespace
Rejected due to lack of isolation and poor scalability in multi-app clusters.

### 2. Separate clusters per environment
Rejected as overkill for current learning and development scope.
