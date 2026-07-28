# ADR-012: Progressive Delivery with Argo Rollouts and Canary Deployments

## Status

Accepted

---

## Context

The PetClinic application was initially deployed using a standard Kubernetes Deployment managed through Helm and synchronized by ArgoCD.

The Kubernetes Deployment strategy provided basic rolling updates:

- new Pods were created,
- old Pods were gradually removed,
- Kubernetes ensured the desired replica count.

However, this approach did not provide controlled traffic management.

The platform requires a production-like deployment model supporting:

- gradual application releases,
- controlled user exposure,
- validation before full rollout,
- traffic shifting between application versions,
- foundation for automated rollback mechanisms.

The previous deployment model:

~~~text
Git Repository

        |

        v

ArgoCD

        |

        v

Kubernetes Deployment

        |

        v

Application Pods
~~~

allowed automated deployments but did not provide progressive delivery capabilities.

---

## Problem

A standard Kubernetes Deployment cannot natively perform traffic-based canary releases.

The rolling update strategy operates on Pod replacement:

~~~text
Old ReplicaSet

        |

        v

New ReplicaSet
~~~

but Kubernetes Services route traffic using labels and selectors only.

This creates limitations:

- no percentage-based traffic splitting,
- no controlled user exposure,
- no deployment validation phase,
- no integration point for automated metric analysis,
- rollback decisions require external tooling or manual intervention.

A safer deployment workflow should support:

~~~text
New Application Version

        |

        v

Small Traffic Exposure

        |

        v

Validation

        |

        v

Increase Traffic

        |

        v

Full Promotion
~~~

---

## Decision

Argo Rollouts was selected as the progressive delivery controller.

The Kubernetes Deployment resource was replaced with an Argo Rollout resource.

The application deployment model changed from:

~~~text
Deployment

        |

        v

ReplicaSet

        |

        v

Pods
~~~

to:

~~~text
Rollout

        |

        v

ReplicaSets

        |

        v

Pods
~~~

Argo Rollouts manages ReplicaSets while providing additional deployment strategies.

---

## Canary Deployment Strategy

The PetClinic application uses the Canary deployment strategy.

The configured rollout flow:

~~~text
Deploy new version

        |

        v

Send 20% traffic to canary

        |

        v

Pause for validation

        |

        v

Send 50% traffic to canary

        |

        v

Pause for validation

        |

        v

Send 100% traffic to new version

        |

        v

Promote new version as stable
~~~

The current rollout configuration:

~~~yaml
strategy:
  canary:
    steps:

      - setWeight: 20

      - pause:
          duration: 60s

      - setWeight: 50

      - pause:
          duration: 60s

      - setWeight: 100
~~~

---

## Traffic Routing Decision

Argo Rollouts requires a traffic routing mechanism to control user traffic.

NGINX Ingress Controller was selected because it is already part of the platform architecture.

The routing configuration:

~~~yaml
trafficRouting:
  nginx:
    stableIngress: petclinic
~~~

allows Argo Rollouts to dynamically manage NGINX Ingress resources.

---

## NGINX Traffic Management Architecture

The deployment architecture changed from:

~~~text
Client

    |

    v

Ingress

    |

    v

Service

    |

    v

Pods
~~~

to:

~~~text
                    Client

                      |

                      v

              NGINX Ingress Controller

                      |

          +-----------+-----------+

          |                       |

          v                       v

 petclinic-stable        petclinic-canary

          |                       |

          v                       v

 Stable ReplicaSet       Canary ReplicaSet

          |                       |

          v                       v

 Stable Pods             Canary Pods
~~~

---

## Stable and Canary Services

Argo Rollouts requires separate Services for traffic separation.

Two Services were introduced:

~~~text
petclinic-stable

        |

        v

Stable ReplicaSet
~~~

and:

~~~text
petclinic-canary

        |

        v

Canary ReplicaSet
~~~

The Services do not directly select Pods.

Instead, Argo Rollouts manages Pod template hashes:

~~~text
Service

    |

    v

rollouts-pod-template-hash

    |

    v

ReplicaSet
~~~

This allows dynamic switching between application versions.

---

## Canary Ingress Management

Before Argo Rollouts:

~~~text
Ingress

    |

    v

petclinic Service

    |

    v

Pods
~~~

After Argo Rollouts:

~~~text
Stable Ingress

    |

    v

petclinic-stable Service


Canary Ingress

    |

    v

petclinic-canary Service
~~~

Argo Rollouts automatically creates and manages:

~~~text
petclinic-petclinic-canary
~~~

Ingress resource.

The generated Ingress contains:

~~~yaml
nginx.ingress.kubernetes.io/canary: true
nginx.ingress.kubernetes.io/canary-weight: <percentage>
~~~

Example:

~~~text
20% traffic

        |

        v

Canary Application Version
~~~

---

## Replica Management

The initial configuration used:

~~~yaml
replicas: 1
~~~

This was increased to:

~~~yaml
replicas: 2
~~~

The reason was to better represent production behaviour.

Multiple replicas allow easier observation of:

- stable Pods,
- canary Pods,
- ReplicaSet transitions,
- traffic migration,
- rollback behaviour.

The resulting deployment state:

~~~text
Stable ReplicaSet

        |

        +-- Pod 1
        |
        +-- Pod 2


Canary ReplicaSet

        |

        +-- Pod 1
        |
        +-- Pod 2
~~~

---

## Rollout Lifecycle

The rollout lifecycle:

~~~text
Git Change

        |

        v

ArgoCD detects change

        |

        v

Argo Rollout creates new ReplicaSet

        |

        v

Canary Pods start

        |

        v

Readiness checks pass

        |

        v

NGINX traffic weight updated

        |

        v

Validation period

        |

        v

Promotion or rollback
~~~

---

## Validation Performed

The implementation was validated using Kubernetes resources.

### Rollout Status

Verified:

~~~bash
kubectl get rollout -n petclinic
~~~

Expected result:

~~~text
Rollout available
Rollout healthy
~~~

---

### ReplicaSet Creation

Verified:

~~~bash
kubectl get rs -n petclinic
~~~

Confirmed:

~~~text
Old ReplicaSet

+

New ReplicaSet
~~~

were managed by Argo Rollouts.

---

### Stable and Canary Services

Verified:

~~~bash
kubectl get svc -n petclinic
~~~

Result:

~~~text
petclinic-stable

petclinic-canary
~~~

---

### Canary Ingress Creation

Verified:

~~~bash
kubectl get ingress -n petclinic
~~~

Result:

~~~text
petclinic

petclinic-petclinic-canary
~~~

---

### Canary Traffic Routing

Verified:

~~~bash
kubectl describe ingress petclinic-petclinic-canary -n petclinic
~~~

Confirmed:

~~~text
nginx.ingress.kubernetes.io/canary: true
~~~

and traffic weight management.

---

## Consequences

### Positive

- Production-like deployment workflow.
- Controlled application exposure.
- Safer application releases.
- Traffic shifting capability.
- Clear separation between stable and canary versions.
- Foundation for automated rollback.
- Better deployment observability.
- Reduced risk during releases.
- Compatible with GitOps workflow.
- Integrates with existing NGINX infrastructure.

---

### Negative

- Additional Kubernetes controller required.
- More Kubernetes resources to maintain.
- Increased deployment complexity.
- Requires understanding of traffic routing.
- Additional operational knowledge required.
- More complex debugging process.

---

## Alternatives Considered

### 1. Continue using Kubernetes Deployment RollingUpdate

Rejected because:

- no traffic percentage control,
- no validation phase,
- no native canary workflow.

---

### 2. Blue/Green Deployment

Rejected for the current stage.

Blue/Green provides full environment switching but does not provide gradual traffic migration.

Canary was selected because it better demonstrates progressive delivery concepts.

---

### 3. Manual Service Switching

Rejected because:

- error prone,
- not automated,
- difficult to integrate with GitOps.

---

### 4. Service Mesh Based Traffic Routing

Rejected for the current implementation.

Solutions such as Istio or Linkerd provide advanced traffic control, but introduce additional platform complexity.

NGINX Ingress was sufficient for the current platform requirements.

---

# Result

The PetClinic platform now supports progressive delivery using Argo Rollouts.

The deployment model changed from:

~~~text
ArgoCD

    |

    v

Kubernetes Deployment

    |

    v

Pods
~~~

to:

~~~text
Git Repository

    |

    v

ArgoCD

    |

    v

Argo Rollouts

    |

    v

NGINX Traffic Routing

    |

    +----------------+

    |                |

    v                v

Stable Version   Canary Version
~~~

The platform is now prepared for the next improvement:

- Prometheus-based AnalysisTemplate,
- automatic rollout validation,
- metric-based promotion,
- automatic rollback on application failures.