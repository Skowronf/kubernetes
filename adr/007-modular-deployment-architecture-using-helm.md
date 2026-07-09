# ADR-002: Modular Deployment Architecture Using Helm Parent Chart

## Status

Accepted

---

## Context

Initially, Kubernetes manifests and Helm resources were maintained in a flatter structure, making deployments less organized and harder to maintain.

The project consists of two major deployment areas:

- PetClinic application
- Observability stack (Grafana, Prometheus, Loki, Promtail)

Although related, these components have different deployment lifecycles and resource requirements. During local development, the observability stack consumes a significant amount of CPU and memory, while it is often unnecessary for application development.

A deployment architecture is needed that:

- separates application and observability concerns,
- allows independent deployments,
- simplifies upgrades,
- supports lightweight local development.

---

## Decision

The deployment structure has been reorganized into a modular Helm architecture.

A parent Helm chart (`petclinic-platform`) now manages two child charts:

- `petclinic`
- `observability`

The repository structure has been updated as follows:

```text
charts/
└── petclinic-platform/
    └── charts/
        ├── petclinic/
        └── observability/
```

GitOps application definitions have also been split into independent applications:

```text
gitops/
└── applications/
    ├── petclinic.yml
    └── observability.yml
```

Deployments and upgrades are performed through Helm, enabling the platform or individual components to be managed consistently.

---

## Rationale

- Separates business application deployment from monitoring infrastructure.
- Improves repository organization and maintainability.
- Enables independent lifecycle management for application and observability components.
- Simplifies Helm upgrades by grouping related resources into charts.
- Reduces local resource consumption by making observability optional.
- Provides a scalable foundation for future platform components.

---

## Consequences

### Positive

- Clear separation of responsibilities between application and observability.
- Better repository organization.
- Simpler maintenance of Helm charts.
- Independent deployments and upgrades.
- Lower CPU and memory usage during local development.
- Easier future expansion of the platform.

### Negative

- Slightly more complex Helm chart hierarchy.
- Parent chart dependencies require additional maintenance.
- Helm values must be managed to enable or disable optional components.

---

## Alternatives Considered

### 1. Keep standalone manifests

Rejected because maintaining loose manifests makes deployments and upgrades more difficult and increases duplication.

### 2. Single Helm chart containing all resources

Rejected because the application and observability stack have different deployment lifecycles and local development requirements.

### 3. Separate repositories for observability

Rejected because it would introduce unnecessary complexity for the current project while providing limited practical benefits.
