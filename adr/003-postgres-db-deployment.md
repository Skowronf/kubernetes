# ADR-003: PostgreSQL Deployment Strategy with Persistent Storage

## Status
Accepted

---

## Context

The PetClinic application requires a relational database to store application data. PostgreSQL was selected as the database engine.

The database must:

- persist data across pod restarts
- be accessible internally within the Kubernetes cluster
- support basic health checking (readiness and liveness)
- integrate with Kubernetes-native service discovery
- remain simple enough for a learning and development environment

A decision was required on how to deploy PostgreSQL in Kubernetes and how to handle persistence.

---

## Decision

PostgreSQL is deployed using a Kubernetes `Deployment` with:

- 1 replica
- container image `postgres:16`
- persistent storage via `PersistentVolumeClaim (PVC)`
- data mounted at `/var/lib/postgresql/data`
- readiness probe using `pg_isready`
- liveness probe using `pg_isready`
- environment variables for database initialization (`POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`)

---

## Rationale

- `Deployment` provides basic lifecycle management and automatic pod replacement
- PVC ensures data persistence across pod restarts and rescheduling
- Readiness and liveness probes improve reliability and detect database failures
- Single replica simplifies setup and avoids distributed database complexity
- Environment variables provide straightforward initialization of PostgreSQL instance
- Kubernetes Service abstraction ensures stable DNS-based access from the application

This approach prioritizes simplicity and learning over full production-grade database orchestration.

---

## Consequences

### Positive

- Data persists across pod restarts due to PVC
- Database automatically restarts on failure (self-healing via Deployment)
- Simple configuration and setup
- Easy integration with application via Kubernetes Service
- Reduced operational complexity compared to clustered database setups

### Negative

- No high availability (single instance database)
- No built-in replication or failover
- Risk of data loss in case of PVC failure or misconfiguration
- No stable identity guarantees compared to StatefulSet
- Not suitable for production-grade workloads

---

## Alternatives Considered

### 1. StatefulSet
Rejected to reduce complexity. While StatefulSet provides stable network identity and better guarantees for storage orchestration, it introduces additional operational overhead not required for this learning setup.

### 2. External Managed PostgreSQL (e.g., cloud database service)
Rejected because the goal was to run the full application stack inside Kubernetes for learning and experimentation.

