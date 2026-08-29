# ADR-016: Separation of Platform Bootstrap and GitOps Application Management

## Status

Accepted

---

## Context

The PetClinic platform is deployed on a local Kubernetes cluster created using kind.

The platform uses ArgoCD as the GitOps controller responsible for managing Kubernetes applications and their configuration.

Initially, the bootstrap process mixed several responsibilities:

- Kubernetes cluster creation
- Cilium installation
- ArgoCD installation
- application namespace creation
- container registry credentials
- application deployment
- certificate management
- application verification

This created an unclear boundary between infrastructure required to operate the platform and applications managed by GitOps.

A clearer separation is required so that:

- platform infrastructure is available before ArgoCD manages applications
- secrets required for application deployment are provisioned before GitOps reconciliation
- ArgoCD is responsible for application lifecycle management
- bootstrap scripts do not continuously manage application resources
- the architecture can later be adapted to a managed Kubernetes environment such as AWS EKS

---

## Decision

The bootstrap process is divided into three logical phases:

1. Platform bootstrap
2. Bootstrap prerequisites
3. GitOps bootstrap

Platform components and prerequisites required by ArgoCD are provisioned using scripts.

Applications and their Kubernetes resources are managed by ArgoCD.

The current bootstrap flow is:

```text
Platform bootstrap
        |
        +-- kind cluster
        |
        +-- Cilium
        |
        +-- ArgoCD
        |
        +-- ArgoCD configuration
        |
        v
Bootstrap prerequisites
        |
        +-- petclinic namespace
        |
        +-- container registry credentials
        |
        v
GitOps bootstrap
        |
        +-- ArgoCD Applications
        |
        +-- cert-manager
        +-- PetClinic
        +-- PostgreSQL
        +-- observability
        |
        v
Local CA provisioning
        |
        +-- local CA secret
        |
        v
Verification and tests
