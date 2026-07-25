# ADR-003: Cilium CNI Adoption and NetworkPolicy Security Model

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

---

## Implemented Network Policies

### Default Deny

All ingress and egress traffic is blocked unless explicitly allowed.

Traffic model:

```text
Any Pod

   |
   X

Unauthorized Communication
```

---

### DNS Access

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

---

### PetClinic to PostgreSQL

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

---

### PostgreSQL Access Control

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

---

### Ingress Controller to PetClinic

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

---

## Network Flow Summary

Allowed traffic:

```text
                    TCP 8080
Ingress NGINX  ----------------->  PetClinic


                    TCP 5432
PetClinic       ----------------->  PostgreSQL


                  TCP/UDP 53
PetClinic       ----------------->  CoreDNS
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

## Rationale

- Introduces a production-like Kubernetes networking architecture.
- Removes dependency on kube-proxy by using Cilium eBPF-based networking.
- Enables advanced Kubernetes network security features.
- Implements the principle of least privilege.
- Prevents unauthorized pod-to-pod communication.
- Reduces the risk of lateral movement after workload compromise.
- Makes application communication dependencies explicit.
- Improves troubleshooting capabilities through better network visibility.
- Creates a foundation for future Kubernetes security improvements.

---

## Consequences

### Positive

- Kubernetes networking is closer to modern production environments.
- kube-proxy is replaced with an eBPF-based implementation.
- Network traffic is controlled through explicit security rules.
- Workloads are isolated by default.
- Security boundaries between components are clearly defined.
- Network dependencies are documented.
- Future platform components can be integrated using explicit policies.

### Negative

- Cluster networking configuration becomes more complex.
- Troubleshooting requires knowledge of Cilium and Kubernetes networking.
- Incorrect NetworkPolicy configuration can block valid application traffic.
- Every new service communication path requires an additional security rule.
- Cilium upgrades require additional validation.

---

## Alternatives Considered

### 1. Keep default kind networking

Rejected because the default networking model does not provide a realistic production Kubernetes environment and limits advanced networking capabilities.

---

### 2. Keep kube-proxy and use Cilium only as CNI

Rejected because kube-proxy replacement provides additional benefits through eBPF-based Service handling and removes an unnecessary networking component.

---

### 3. Use Calico instead of Cilium

Rejected because Cilium provides stronger observability capabilities, eBPF-based networking, and modern Kubernetes networking features.

---

### 4. Allow unrestricted pod communication

Rejected because unrestricted communication does not provide sufficient workload isolation and does not follow production Kubernetes security practices.

---

## Validation

The implementation was validated by checking:

### Network Policy Validation

Allowed communication was verified:

```text
Ingress NGINX -> PetClinic
PetClinic -> PostgreSQL
PetClinic -> CoreDNS
```

Blocked communication was verified:

```text
Unauthorized Pod -> PostgreSQL
Unauthorized Pod -> PetClinic
```

---

## Result

The Kubernetes cluster now uses a Cilium-based networking architecture with kube-proxy replacement and a zero-trust NetworkPolicy model.

All workload communication is explicitly defined and enforced, providing a more secure and production-like Kubernetes environment.