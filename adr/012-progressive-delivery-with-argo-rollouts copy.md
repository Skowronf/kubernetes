# ADR-014: Automated Canary Rollback with Prometheus Analysis

## Status

Accepted

---

## Context

The PetClinic application already supported progressive delivery using Argo Rollouts and Canary Deployments.

The previous deployment flow:

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

Canary Deployment

        |

        v

Manual Validation

        |

        v

Promotion
~~~

allowed controlled traffic migration, but deployment validation still required manual verification.

A production-like deployment process should automatically evaluate application health during a canary release and make deployment decisions based on real application metrics.

The platform requires:

- automated canary validation,
- metric-based deployment decisions,
- automatic rollback when application health degrades,
- integration with existing Prometheus monitoring.

---

## Problem

A canary deployment without automated analysis has limitations:

- requires manual monitoring,
- depends on operator availability,
- increases the risk of promoting broken versions,
- does not automatically react to application failures.

The desired workflow:

~~~text
New Application Version

        |

        v

Canary Traffic

        |

        v

Prometheus Metrics Evaluation

        |

        +----------------+

        |                |

        v                v

    Promote          Rollback
~~~

requires a mechanism that connects application metrics with deployment lifecycle decisions.

---

## Decision

Argo Rollouts AnalysisTemplate was introduced as the validation mechanism for Canary deployments.

Prometheus was selected as the metrics provider.

The deployment flow was extended:

~~~text
Deploy New Version

        |

        v

Create Canary ReplicaSet

        |

        v

Send Traffic To Canary

        |

        v

Create AnalysisRun

        |

        v

Query Prometheus

        |

        +----------------+

        |                |

        v                v

 Successful         Failed

        |                |

        v                v

 Continue        Abort Rollout

        |                |

        v                v

 Promote        Restore Stable Version
~~~

---

## AnalysisTemplate Implementation

A new Kubernetes resource was introduced:

~~~yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
~~~

The template defines:

- Prometheus provider,
- metric query,
- success condition,
- failure condition,
- measurement interval.

Example:

~~~yaml
metrics:
  - name: http-success-rate

    interval: 30s
    count: 2

    successCondition: result[0] >= 0.50
    failureCondition: result[0] < 0.50

    provider:
      prometheus:
        address:
          http://observability-kube-prometh-prometheus.observability.svc.cluster.local:9090
~~~

The metric evaluates application HTTP success rate.

---

## Prometheus Integration

Argo Rollouts communicates with Prometheus through the internal Kubernetes Service:

~~~text
Argo Rollouts Controller

        |

        v

Kubernetes Service

        |

        v

Prometheus HTTP API

        |

        v

PromQL Query Result
~~~

Prometheus remains responsible for collecting metrics.

Argo Rollouts only consumes the query result and makes rollout decisions.

---

## Rollout Integration

The existing Canary strategy was extended with Analysis steps.

Before:

~~~text
Canary 20%

        |

        v

Pause

        |

        v

Canary 50%

        |

        v

Pause

        |

        v

100%
~~~

After:

~~~text
Canary 20%

        |

        v

AnalysisRun

        |

        v

Canary 50%

        |

        v

AnalysisRun

        |

        v

100%
~~~

Example:

~~~yaml
steps:

  - setWeight: 20

  - analysis:
      templates:
        - templateName: petclinic-success-rate

  - pause:
      duration: 60s

  - setWeight: 50

  - analysis:
      templates:
        - templateName: petclinic-success-rate

  - pause:
      duration: 60s

  - setWeight: 100
~~~

---

## Rollback Scenario

The rollback mechanism was validated by deploying a new application version and introducing HTTP failures.

The observed flow:

~~~text
New Version

        |

        v

Canary Traffic Enabled

        |

        v

HTTP Errors Generated

        |

        v

Prometheus Detects Lower Success Rate

        |

        v

AnalysisRun Failed

        |

        v

Argo Rollouts Aborts Deployment

        |

        v

Stable ReplicaSet Restored
~~~

The failed AnalysisRun result:

~~~text
HTTP Success Rate:

0.287

Required:

>= 0.50
~~~

Result:

~~~text
AnalysisRun: Failed

Rollout: Aborted

Stable Version: Restored
~~~

---

## Validation Performed

### AnalysisTemplate

Verified:

~~~bash
kubectl get analysistemplate -n petclinic
~~~

Result:

~~~text
petclinic-success-rate
~~~

---

### AnalysisRun Creation

Verified:

~~~bash
kubectl get analysisrun -n petclinic
~~~

Confirmed:

~~~text
Successful AnalysisRun

+

Failed AnalysisRun
~~~

were created during rollout e

## Consequences

### Positive

- Automated canary validation.
- Automatic rollback of unhealthy releases.
- Deployment decisions based on real application metrics.
- Reduced dependency on manual verification.
- Better production-like delivery workflow.
- Full integration with GitOps deployment model.
- Clear audit trail through AnalysisRun resources.

---

### Negative

- Incorrect Prometheus queries can trigger false rollbacks.
- Threshold configuration requires tuning.
- Application metrics must be reliable.
- Additional Kubernetes resources increase operational complexity.
- Debugging requires understanding of both monitoring and deployment systems.

---

## Alternatives Considered

### 1. Manual Application Verification

Rejected because:

- requires human intervention,
- does not provide automatic rollback,
- does not scale with frequent deployments.

---

### 2. Kubernetes Deployment RollingUpdate

Rejected because:

- no metric-based validation,
- no canary traffic control,
- no automated rollback based on application behaviour.

---

### 3. External Monitoring Trigger

Rejected because:

- Argo Rollouts provides native Prometheus integration,
- additional external automation would increase complexity.

---

# Result

The PetClinic platform now supports automated progressive delivery:

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

Canary Deployment

        |

        v

Prometheus AnalysisRun

        |

        +----------------+

        |                |

        v                v

    Promotion       Automatic Rollback
~~~

The platform can now automatically reject unhealthy application versions based on runtime metrics.

Future improvements:

- improve Prometheus SLO queries,
- introduce latency-based analysis,
- increase analysis duration,
- add more production-like failure scenarios.