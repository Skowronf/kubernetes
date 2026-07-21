# ADR-004: Migrate PostgreSQL Workload from Deployment to StatefulSet

## Status

Accepted

---

## Context

The platform initially deployed PostgreSQL using a Kubernetes `Deployment` with a manually created `PersistentVolumeClaim`.

The initial architecture was:

```text
Deployment
    |
    |
PostgreSQL Pod
    |
    |
PersistentVolumeClaim
```

While this approach works for simple development workloads, `Deployment` is designed primarily for stateless applications where Pods are interchangeable.

Database workloads require additional guarantees:

* stable Pod identity,
* predictable network addressing,
* persistent storage association,
* controlled Pod lifecycle management.

The current Deployment-based approach has several limitations:

* PostgreSQL Pods receive randomly generated names.
* A recreated Pod is treated as a completely new instance.
* Storage is manually attached using a PVC reference.
* Future scaling scenarios would not provide independent database identities.

The platform requires a Kubernetes-native solution that better represents how stateful workloads are managed.

---

## Decision

The PostgreSQL workload is migrated from a Kubernetes `Deployment` to a `StatefulSet`.

The new architecture uses:

* `StatefulSet` for PostgreSQL lifecycle management.
* Headless `Service` for stable DNS discovery.
* `volumeClaimTemplates` for automatic PersistentVolumeClaim creation.

The new architecture is:

```text
StatefulSet postgres

        |
        |
        +----------------+
        |                |
        v                v

   postgres-0       postgres-1

        |                |
        v                v

postgres-data-   postgres-data-
postgres-0       postgres-1
```

Each StatefulSet replica receives:

* a stable Pod identity,
* a dedicated PersistentVolumeClaim,
* an independent PersistentVolume.

Example:

```text
postgres-0
    |
    |
postgres-data-postgres-0
```

and:

```text
postgres-1
    |
    |
postgres-data-postgres-1
```

The PostgreSQL Service is converted into a Headless Service:

```yaml
clusterIP: None
```

This enables stable DNS records:

```text
postgres-0.postgres.petclinic.svc.cluster.local
```

---

## Database Replication Consideration

StatefulSet does **not** provide database replication.

When scaling PostgreSQL replicas:

```yaml
replicas: 2
```

Kubernetes creates independent PostgreSQL instances:

```text
postgres-0

    |
    |
    PV-0


postgres-1

    |
    |
    PV-1
```

The PersistentVolumes do not communicate with each other and Kubernetes does not synchronize database data.

Without additional PostgreSQL replication configuration:

* data written to `postgres-0` exists only on `postgres-0`,
* data written to `postgres-1` exists only on `postgres-1`,
* application requests routed to different instances may return inconsistent results.

Database synchronization must be handled by PostgreSQL-native mechanisms or higher-level tooling.

Future PostgreSQL high availability requires additional components such as:

* PostgreSQL streaming replication,
* Patroni,
* PostgreSQL Operators (for example CloudNativePG),
* managed database replication solutions.

For the current project phase, PostgreSQL remains deployed as a single StatefulSet replica:

```yaml
replicas: 1
```

---

## Rationale

* Provides stable identity required by stateful applications.
* Ensures PostgreSQL Pod recreation keeps the same logical identity.
* Automatically creates dedicated PVCs for StatefulSet replicas.
* Separates Kubernetes storage management from database replication concerns.
* Creates a foundation for future PostgreSQL high availability solutions.
* Better reflects production Kubernetes workload patterns.

---

## Consequences

### Positive

* PostgreSQL is managed using the Kubernetes primitive designed for stateful workloads.
* Pod names and network identity remain stable.
* Storage lifecycle is managed together with the StatefulSet.
* Future PostgreSQL replication solutions can build on top of stable Pod identities.
* Architecture is closer to production Kubernetes environments.

### Negative

* StatefulSets introduce additional complexity compared to Deployments.
* StatefulSet alone does not provide database replication.
* Scaling PostgreSQL replicas does not automatically create a synchronized database cluster.
* Additional operational knowledge is required for backup, recovery, replication, and failover.
* Production PostgreSQL deployments require additional tooling or managed services.

---

## Alternatives Considered

### 1. Keep PostgreSQL as Deployment

Rejected because Deployments are designed for stateless workloads and do not provide stable identity or storage management required by databases.

---

### 2. Scale PostgreSQL StatefulSet replicas without replication

Rejected.

Although StatefulSet can create multiple PostgreSQL instances, each instance receives independent storage and database state.

Without PostgreSQL replication, multiple replicas would behave as independent databases and could lead to inconsistent application data.

---

### 3. Use a PostgreSQL Operator

Postponed.

Operators such as CloudNativePG or Crunchy PostgreSQL Operator provide production-grade database lifecycle management, including:

* replication,
* failover,
* backups,
* recovery.

The platform currently focuses on understanding native Kubernetes primitives before introducing higher-level abstractions.

---

### 4. Use a managed PostgreSQL service

Rejected for the current phase.

Managed databases such as AWS RDS PostgreSQL provide production-grade database availability, but the current goal is to demonstrate Kubernetes stateful workload management before moving to cloud infrastructure.

---

## Validation

The migration is considered successful when:

1. PostgreSQL runs as:

```text
postgres-0
```

instead of a Deployment-generated Pod name.

2. StatefulSet exists:

```bash
kubectl get statefulset -n petclinic
```

3. StatefulSet creates a dedicated PVC:

```bash
kubectl get pvc -n petclinic
```

Example:

```text
postgres-data-postgres-0
```

4. Deleting the Pod recreates the same identity:

```bash
kubectl delete pod postgres-0 -n petclinic
```

Expected:

```text
postgres-0 recreated
```

5. Persistent storage remains attached after Pod recreation.

---
