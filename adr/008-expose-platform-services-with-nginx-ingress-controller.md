# ADR-003: Expose Platform Services Through NGINX Ingress Controller

## Status

Accepted

---

## Context

The platform exposes multiple HTTP-based services, including:

- PetClinic application
- Prometheus
- Grafana
- Argo CD (future)

Initially, services could be accessed directly using Kubernetes `NodePort` or `LoadBalancer` Services. While suitable for simple environments, exposing each service individually becomes less maintainable as the platform grows.

The platform requires an ingress solution that:

- provides a single HTTP entry point,
- routes traffic based on host names,
- allows multiple services to share the same external endpoint,
- resembles a production Kubernetes deployment,
- integrates well with GitOps.

---

## Decision

The platform uses the **NGINX Ingress Controller** deployed via Helm and managed by Argo CD.

The controller is deployed as a `DaemonSet` with `hostPort` enabled, allowing every Kubernetes node to accept HTTP/HTTPS traffic without requiring a cloud `LoadBalancer`.

Application Services remain internal (`ClusterIP`) and are exposed only through Kubernetes `Ingress` resources.

Ingress resources define host-based routing, for example:

- `petclinic.local` → PetClinic
- `prometheus.local` → Prometheus
- `grafana.local` → Grafana

The Ingress Controller is deployed after application workloads using an Argo CD sync wave to ensure backend Services are available before external routing is configured.

---

## Rationale

- Keeps application Services internal to the cluster.
- Provides a single entry point for all HTTP traffic.
- Supports host-based routing for multiple platform components.
- Mirrors production Kubernetes networking practices.
- Simplifies future adoption of HTTPS and TLS certificates.
- Integrates naturally with GitOps and declarative Kubernetes resources.

---

## Consequences

### Positive

- Internal Services are not exposed directly.
- Multiple applications can share the same HTTP endpoint.
- Easier addition of new services through Ingress resources.
- Cleaner and more production-like networking architecture.
- Future TLS support requires only Ingress configuration changes.

### Negative

- Introduces an additional infrastructure component.
- Requires DNS or local `hosts` file configuration for custom host names.
- Ingress configuration adds another layer that must be maintained and monitored.

---

## Alternatives Considered

### 1. Expose every Service using NodePort

Rejected because each application would require a separate external port, making the platform harder to use and less representative of production deployments.

### 2. Use LoadBalancer Services

Rejected because the project targets local Kubernetes environments where cloud load balancers are typically unavailable.

### 3. Access Services using `kubectl port-forward`

Rejected because it is intended for temporary development and debugging rather than permanent platform access.
