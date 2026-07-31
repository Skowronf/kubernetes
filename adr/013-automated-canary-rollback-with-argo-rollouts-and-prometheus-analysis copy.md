# ADR-012: Progressive Delivery Using Argo Rollouts and Canary Deployments

## Status
Accepted

---

## Context

The PetClinic platform uses Kubernetes as the runtime environment and follows a GitOps-based deployment approach.

Traditional Kubernetes Deployment updates replace application versions immediately, which can introduce risk when deploying new releases. A faulty application version can affect all users before problems are detected.

A safer deployment strategy is required to:

- reduce the impact of failed releases
- validate new application versions gradually
- provide the ability to control traffic distribution between application versions
- support automated deployment workflows

The platform requires a Kubernetes-native solution that integrates with the existing GitOps workflow.

---

## Decision

Argo Rollouts is used instead of the standard Kubernetes Deployment resource for applications requiring progressive delivery.

Canary deployments are introduced to gradually release new application versions.

The deployment process follows:

1. deploy a new application version
2. create a new canary ReplicaSet
3. gradually shift traffic from the stable version to the canary version
4. verify application behavior during rollout
5. promote the canary version if validation succeeds
6. rollback automatically if validation fails

The rollout process is managed through Argo Rollouts resources instead of standard Kubernetes Deployment updates.

---

## Rationale

- Canary deployments reduce the blast radius of faulty releases
- New versions can be validated before receiving full traffic
- Rollback capability improves deployment safety
- Argo Rollouts integrates with Kubernetes-native workflows
- The approach fits GitOps principles because rollout configuration is managed as code
- Progressive delivery provides a controlled path from development changes to production-like environments

---

## Consequences

### Positive

- Safer application releases
- Reduced risk of introducing broken versions to all users
- Ability to gradually introduce new versions
- Better visibility into deployment progress
- Rollback can be automated based on rollout conditions
- Deployment strategy becomes declarative and version-controlled

### Negative

- Increased deployment complexity compared to standard Kubernetes Deployments
- Requires additional Kubernetes resources and operational knowledge
- Rollout configuration needs to be maintained alongside application manifests
- Additional monitoring and validation mechanisms may be required

---

## Alternatives Considered

### 1. Standard Kubernetes Deployment rolling updates

Rejected because rolling updates immediately replace application instances without providing advanced traffic control or gradual validation.

---

### 2. Manual validation after deployment

Rejected because it depends on human intervention and increases reaction time when problems occur.

---

### 3. Blue-Green deployments

Considered as an alternative deployment strategy.

Not selected because canary deployments provide more gradual traffic migration and allow incremental validation of new versions.

---

## Future Improvements

- Add automated metric-based analysis during canary releases
- Integrate Prometheus-based health evaluation
- Define automatic rollback conditions
- Improve rollout observability through dashboards and alerts