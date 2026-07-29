# ADR-010: Cilium CNI Adoption and NetworkPolicy Security Model

## Status

Accepted

---

## Context

Initially, the Kubernetes cluster was running with the default networking configuration provided by kind.

The default setup relied on:

- default CNI networking,
- kube-proxy for Kubernetes Service routing,
- unrestricted pod-to-pod communication unless additional security rules were introduced.

While this approach is sufficient for basic Kubernetes workloads, it does not represent a production-grade networking architecture.

The platform requires:

- production-like Kubernetes networking,
- advanced network policy enforcement,
- workload isolation,
- explicit communication rules between services,
- improved visibility into network traffic.

The project consists of multiple workloads running inside Kubernetes:

- PetClinic application
- PostgreSQL database
- Observability stack

These components should not communicate freely. Network access should follow the principle of least privilege.

---

## Decision

Cilium has been selected as the Kubernetes networking provider.

The kind cluster configuration was modified to disable the default networking components:

```yaml
networking:
  disableDefaultCNI: true
  kubeProxyMode: none
```

This removes the default CNI installation and disables kube-proxy.

Cilium was installed with kube-proxy replacement enabled:

```bash
cilium install \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=127.0.0.1 \
  --set k8sServicePort=6443
```

Cilium is now responsible for:

- Kubernetes pod networking,
- Kubernetes Service implementation,
- network policy enforcement,
- eBPF-based packet processing.

---

## Cilium Architecture

After the change, the networking architecture is:

```text
Kubernetes Cluster

        |
        |
        v

      Cilium
        |
        |
        +----------------+
        |                |
        v                v

 eBPF Datapath     Service Handling

        |
        |
        v

 Kubernetes Workloads
```

Cilium replaces traditional kube-proxy packet processing with an eBPF-based networking layer.

---

## Network Security Model

After introducing Cilium, a default deny security model was implemented using Kubernetes NetworkPolicy.

All traffic inside the `petclinic` namespace is denied by default.

Default policy:

```yaml
policyTypes:
  - Ingress
  - Egress
```

Only explicitly required communication paths are allowed.

The security model follows a zero-trust approach:

- no workload communication is allowed by default,
- every required communication path must be explicitly defined,
- access is granted based on workload identity and required ports.

---

# Implemented Network Policies

## Default Deny

All ingress and egress traffic is blocked unless explicitly allowed.

Policy:

```text
deny-all
```

Traffic model:

```text
Any Pod

   |
   X

Unauthorized Communication
```

---

## DNS Access

Applications require DNS resolution to communicate with Kubernetes Services.

Allowed communication:

```text
PetClinic Pod

      |
      | TCP/UDP 53
      |

CoreDNS
(kube-system namespace)
```

Policy:

```text
allow-dns
```

DNS access is required because Kubernetes Services are resolved using cluster DNS.

---

## PetClinic to PostgreSQL

The PetClinic application requires access to PostgreSQL.

Allowed communication:

```text
PetClinic Pod

      |
      | TCP 5432
      |

PostgreSQL Pod
```

Policy:

```text
petclinic-allow-to-postgres
```

This allows only the application workload to access the database.

---

## PostgreSQL Access Control

PostgreSQL accepts connections only from PetClinic.

Allowed communication:

```text
PetClinic Pod

      |
      | TCP 5432
      |

PostgreSQL Pod
```

Policy:

```text
postgres-allow-petclinic
```

This prevents other workloads from accessing the database directly.

---

## Ingress Controller to PetClinic

External HTTP traffic enters the cluster through NGINX Ingress Controller.

Allowed communication:

```text
Ingress NGINX Controller

          |
          | TCP 8080
          |

PetClinic Pod
```

Policy:

```text
allow-ingress-nginx
```

Only traffic originating from the ingress controller namespace is accepted.

---

# Observability Network Model

The observability stack runs in a separate namespace:

```text
observability
```

The stack contains:

- Prometheus
- Grafana
- Loki
- Promtail

The `petclinic` namespace remains isolated, therefore observability communication must be explicitly considered.

---

## Prometheus Metrics Collection

Prometheus collects metrics by actively connecting to application endpoints.

Communication flow:

```text
Prometheus

(namespace: observability)

        |
        |
        | HTTP GET /actuator/prometheus
        | TCP 8080
        |
        v

PetClinic Service

(namespace: petclinic)

        |
        |
        v

PetClinic Pod
```

Because Prometheus initiates the connection, the PetClinic pod requires an ingress rule allowing Prometheus.

Required policy:

```text
allow-prometheus-scrape
```

Example:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-prometheus-scrape
  namespace: petclinic

spec:
  podSelector:
    matchLabels:
      app: petclinic

  policyTypes:
  - Ingress

  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: observability
    ports:
    - protocol: TCP
      port: 8080
```

The ServiceMonitor resource allows Prometheus discovery across namespaces:

```yaml
namespaceSelector:
  matchNames:
    - petclinic
```

However, ServiceMonitor discovery does not bypass Kubernetes NetworkPolicy. Network access must still be allowed.

---

## Loki Log Collection

Loki behaves differently from Prometheus.

Logs are collected through Promtail.

Communication flow:

```text
PetClinic Container

        |
        |
        v

Container stdout

        |
        |
        v

Node filesystem

/var/log/pods/

        |
        |
        v

Promtail
(namespace: observability)

        |
        |
        v

Loki
```

Promtail does not connect directly to the PetClinic pod over the network.

It reads container logs from the Kubernetes node filesystem and forwards them to Loki.

Because there is no pod-to-pod network connection:

```text
Promtail -> PetClinic Pod
```

NetworkPolicy does not block log collection.

This explains why Loki continues receiving logs even when the `petclinic` namespace uses:

```yaml
deny-all
```

NetworkPolicy controls network traffic, not node-level log file access.

---

# Network Flow Summary

Allowed network traffic:

```text
                    TCP 8080
Ingress NGINX  ----------------->  PetClinic


                    TCP 8080
Prometheus      ----------------->  PetClinic
                                   /actuator/prometheus


                    TCP 5432
PetClinic       ----------------->  PostgreSQL


                  TCP/UDP 53
PetClinic       ----------------->  CoreDNS
```

Log collection flow:

```text
PetClinic Container

        |
        v

Node filesystem

        |
        v

Promtail

        |
        v

Loki
```

Blocked traffic:

```text
Random Pod
    |
    X
    |
PostgreSQL


Random Pod
    |
    X
    |
PetClinic
```

---

# Rationale

- Introduces a production-like Kubernetes networking architecture.
- Removes dependency on kube-proxy by using Cilium eBPF-based networking.
- Enables advanced Kubernetes network security features.
- Implements the principle of least privilege.
- Prevents unauthorized pod-to-pod communication.
- Reduces the risk of lateral movement after workload compromise.
- Makes application communication dependencies explicit.
- Improves troubleshooting capabilities through better network visibility.
- Separates application networking from observability data collection.
- Demonstrates the difference between active metric scraping and passive log collection.
- Creates a foundation for future Kubernetes security improvements.

---

# Consequences

## Positive

- Kubernetes networking is closer to modern production environments.
- kube-proxy is replaced with an eBPF-based implementation.
- Network traffic is controlled through explicit security rules.
- Workloads are isolated by default.
- Security boundaries between components are clearly defined.
- Network dependencies are documented.
- Prometheus access is controlled explicitly.
- Loki log collection continues without weakening application isolation.
- Future platform components can be integrated using explicit policies.

## Negative

- Cluster networking configuration becomes more complex.
- Troubleshooting requires knowledge of Cilium and Kubernetes networking.
- Incorrect NetworkPolicy configuration can block valid application traffic.
- Every new service communication path requires an additional security rule.
- Cilium upgrades require additional validation.
- Observability components require understanding of different data collection models.

---

# Alternatives Considered

## 1. Keep default kind networking

Rejected because the default networking model does not provide a realistic production Kubernetes environment and limits advanced networking capabilities.

---

## 2. Keep kube-proxy and use Cilium only as CNI

Rejected because kube-proxy replacement provides additional benefits through eBPF-based Service handling and removes an unnecessary networking component.

---

## 3. Use Calico instead of Cilium

Rejected because Cilium provides stronger observability capabilities, eBPF-based networking, and modern Kubernetes networking features.

---

## 4. Allow unrestricted pod communication

Rejected because unrestricted communication does not provide sufficient workload isolation and does not follow production Kubernetes security practices.

---

## Validation

The implementation was validated by checking:

## Network Policy Validation

Allowed communication was verified:

```text
Ingress NGINX -> PetClinic

PetClinic -> PostgreSQL

PetClinic -> CoreDNS

Prometheus -> PetClinic metrics endpoint
```

Blocked communication was verified:

```text
Unauthorized Pod -> PostgreSQL

Unauthorized Pod -> PetClinic
```

---

## Observability Validation

Metrics:

```text
Prometheus -> PetClinic /actuator/prometheus
```

Logs:

```text
PetClinic stdout
        |
        v
Promtail
        |
        v
Loki
```

The difference between metrics collection and log collection was verified.

---

# Result

The Kubernetes cluster now uses a Cilium-based networking architecture with kube-proxy replacement and a zero-trust NetworkPolicy model.

All workload network communication is explicitly defined and enforced.

The observability stack remains functional while respecting workload isolation:

- Prometheus requires explicit network access to scrape metrics.
- Loki receives logs through Promtail node-level collection without requiring direct pod network access.

The platform now provides a more secure and production-like Kubernetes networking environment.