# ADR-011: Container Image Registry Integration and GitOps Image Versioning

## Status

Accepted

---

## Context

Initially, the PetClinic application deployment relied on locally built Docker images loaded directly into the kind Kubernetes cluster.

This approach was suitable for local development but did not represent a production-like Kubernetes deployment model.

The container image existed only inside the local Docker environment and was not available outside the developer machine.

The platform requires:

- immutable application versions,
- external container image storage,
- reproducible deployments,
- GitOps-compatible image references,
- traceability between source code and deployed artifact,
- foundation for future automated rollback mechanisms.

---

## Problem

Using a static image tag:

~~~yaml
image:
  repository: petclinic
  tag: ci
~~~

created several limitations:

- the deployed version was not linked to a specific source code revision,
- rollback to a previous version was difficult,
- Kubernetes depended on local Docker state,
- the deployment process was not portable,
- the workflow was not compatible with production Kubernetes environments.

The previous model:

~~~text
Developer Laptop

        |
        v

Local Docker Image

        |
        v

Kubernetes Cluster
~~~

does not represent how production Kubernetes workloads are normally delivered.

A production-style workflow should be:

~~~text
Source Code

    |
    v

Container Build

    |
    v

Container Registry

    |
    v

Kubernetes Pull

    |
    v

Running Workload
~~~

---

## Decision

GitHub Container Registry (GHCR) was selected as the container image registry.

Application images are stored externally and versioned using immutable tags based on Git commit SHA.

Example:

~~~text
ghcr.io/skowronf/petclinic:a82f91c
~~~

The image tag represents the exact source code revision used to build the container.

Relationship:

~~~text
Git Commit

a82f91c


        =


Container Image

ghcr.io/skowronf/petclinic:a82f91c
~~~

---

## Private Registry Authentication

The PetClinic container image is stored in a private GitHub Container Registry repository.

Because Kubernetes nodes pull container images directly from the registry, the cluster requires authentication credentials.

ArgoCD is not responsible for pulling container images.

ArgoCD manages Kubernetes resources, while Kubernetes runtime authenticates against GHCR.

The responsibility separation is:

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

kubelet

        |
        v

GHCR
~~~

---

## GHCR Authentication Model

A Kubernetes Docker registry secret was created:

~~~bash
kubectl create secret docker-registry ghcr-secret \
  --namespace petclinic \
  --docker-server=ghcr.io \
  --docker-username=<github-user> \
  --docker-password=<github-token>
~~~

The created secret type:

~~~text
kubernetes.io/dockerconfigjson
~~~

stores registry credentials required for pulling private container images.

The secret is referenced by the PetClinic Deployment:

~~~yaml
spec:
  template:
    spec:
      imagePullSecrets:
        - name: ghcr-secret
~~~

---

## Image Pull Authentication Flow

The image pull process:

~~~text
Pod creation

        |
        v

Kubernetes kubelet

        |
        v

Read imagePullSecret

        |
        v

Authenticate against GHCR

        |
        v

Pull container image

        |
        v

Start container
~~~

Without the secret, Kubernetes attempts anonymous access:

~~~text
Kubernetes

        |
        v

GHCR anonymous token request

        |
        v

401 Unauthorized
~~~

---

## Secret Management Decision

For the current local development environment, GHCR credentials are provisioned manually during cluster setup.

Credentials are not stored inside Git because secrets must not be committed to source control.

Current model:

~~~text
Bootstrap Process

        |
        v

Kubernetes Secret

        |
        v

Deployment imagePullSecret reference
~~~

Future production implementation should replace manually managed secrets with a dedicated secret management solution:

- External Secrets Operator,
- Hashicorp Vault,
- cloud secret managers,
- workload identity based authentication.

---

## New Image Delivery Architecture

~~~text
Developer

    |
    v

Git Repository

    |
    v

Build Process

    |
    v

Docker Image

ghcr.io/skowronf/petclinic:<commit-sha>

    |
    v

GHCR

    |
    v

Kubernetes

    |
    v

Running Pod
~~~

---

## Build Process

The previous local-only image build:

~~~bash
docker build -t petclinic:ci .
~~~

was replaced with a registry-based image build:

~~~bash
docker build \
  -t ghcr.io/skowronf/petclinic:<commit-sha> .
~~~

The image version is generated from Git metadata:

~~~bash
git rev-parse --short HEAD
~~~

Example:

~~~text
Git commit:

a82f91c84bd71


Container image:

ghcr.io/skowronf/petclinic:a82f91c
~~~

---

## Kubernetes Image Configuration

The Helm values were changed from:

~~~yaml
image:
  repository: petclinic
  tag: ci
~~~

to:

~~~yaml
image:
  repository: ghcr.io/skowronf/petclinic
  tag: <commit-sha>

imagePullSecrets:
  - name: ghcr-secret
~~~

The Kubernetes Deployment now references an externally stored immutable image with authentication support.

---

## Image Pull Behaviour

The Kubernetes Deployment uses:

~~~yaml
imagePullPolicy: Always
~~~

The image retrieval flow:

~~~text
Kubernetes Pod

        |
        v

Kubelet

        |
        v

Container Runtime

        |
        v

imagePullSecret

        |
        v

GHCR

        |
        v

Container Image
~~~

---

## Kind Cluster Changes

Previously, application images were manually injected:

~~~bash
kind load docker-image petclinic:ci
~~~

This step was removed.

The kind cluster is now responsible only for Kubernetes infrastructure creation.

~~~text
kind

    |
    v

Kubernetes Cluster
~~~

Application images are delivered through GHCR.

---

## Bootstrap Order

The bootstrap process was updated to include registry authentication.

The new order:

~~~text
Create Kubernetes Cluster

        |
        v

Install Cilium

        |
        v

Create Application Namespace

        |
        v

Create GHCR Pull Secret

        |
        v

Apply NetworkPolicy

        |
        v

Deploy Applications through ArgoCD
~~~

The namespace must exist before namespace-scoped resources such as secrets and NetworkPolicies can be created.

---

## GitOps Integration

ArgoCD continues to use Git as the single source of truth.

ArgoCD observes only committed repository changes.

The deployment flow:

~~~text
Local Change

    |
    v

Git Commit

    |
    v

Git Repository

    |
    v

ArgoCD Reconciliation

    |
    v

Kubernetes Deployment
~~~

---

## Final Deployment Architecture

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

Container Runtime

        |
        v

imagePullSecret

        |
        v

GHCR

        |
        v

PetClinic Container
~~~

---

## Rationale

- Container images are no longer tied to developer machines.
- Every deployed version can be traced to a Git revision.
- Deployments become reproducible.
- Kubernetes follows a production-like image delivery model.
- ArgoCD remains the deployment controller.
- Immutable image versions provide rollback capability.
- Private registry access is explicitly configured.
- Registry credentials are separated from application source code.
- Future CI/CD automation can update image versions automatically.
- The architecture supports progressive delivery strategies.

---

## Consequences

### Positive

- Production-like container delivery workflow.
- Clear relationship between source code and deployed artifact.
- Easier debugging of deployed versions.
- Foundation for automated rollback.
- Removal of kind-specific image loading.
- Better deployment traceability.
- CI/CD integration becomes straightforward.
- Kubernetes can securely pull private container images.
- Container registry access is explicitly controlled.

### Negative

- Requires container registry availability.
- Private registries require Kubernetes image pull credentials.
- Image updates require Git changes.
- Registry management becomes an additional operational responsibility.
- Local development requires registry access.
- Registry credentials require lifecycle management.
- Token rotation must be handled.
- Secret distribution becomes part of cluster bootstrap.

---

## Alternatives Considered

### 1. Continue using kind load docker-image

Rejected because it only works for local clusters and does not represent production deployment patterns.

---

### 2. Use mutable tags such as latest or ci

Rejected because mutable tags make deployments difficult to reproduce and complicate rollback.

---

### 3. Store container images inside Git repository

Rejected because container artifacts should be stored in a container registry rather than source control.

---

### 4. Use Docker Hub instead of GHCR

Rejected because GHCR integrates naturally with GitHub-based workflows and repository permissions.

---

## Validation

### Image Build

Verified:

~~~text
Docker image created successfully
~~~

---

### Registry Push

Verified:

~~~text
Image available in GHCR
~~~

---

### Kubernetes Registry Authentication

Verified:

~~~text
Private GHCR image pull

        |

Kubernetes imagePullSecret

        |

Successful container startup
~~~

---

### Kubernetes Pull

Verified:

~~~text
Kubernetes successfully pulls image from GHCR
~~~

---

### ArgoCD Synchronization

Verified:

~~~text
Git change detected

        |

Application becomes OutOfSync

        |

ArgoCD sync deploys new image version
~~~

---

# Result

The PetClinic platform now uses an external container registry with immutable image versioning and authenticated private image delivery.

The deployment model moved from:

~~~text
kind load docker-image

        |

Kubernetes
~~~

to:

~~~text
Git

↓

Container Build

↓

GHCR

↓

ArgoCD

↓

Kubernetes

↓

Authenticated Image Pull
~~~

This provides the required foundation for future platform improvements:

- CI/CD automation,
- image promotion,
- canary deployments,
- metric-based rollback using Prometheus,
- progressive delivery with Argo Rollouts.