# ADR-013: Automated Canary Rollback with Argo Rollouts and Prometheus Analysis

## Status
Accepted

---

## Context

The platform already supports progressive delivery using:

- ArgoCD for GitOps deployment management
- Argo Rollouts for canary deployments
- NGINX Ingress traffic routing
- Stable and Canary Kubernetes Services

A manual canary verification process was insufficient because deployment decisions depended on human observation.

A decision was required to introduce automated validation of new application versions using application health metrics.

The goal was:

- deploy a new version gradually
- send limited traffic to the canary version
- evaluate application health automatically
- rollback when metrics indicate a broken release

---

## Decision

Argo Rollouts AnalysisTemplate was introduced with Prometheus as the metrics provider.

During canary deployment, Argo Rollouts executes an AnalysisRun which evaluates HTTP success rate.

The rollout flow is:
