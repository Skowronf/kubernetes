# ADR-006: Health Checks and Startup Reliability Using Probes and Init Containers

## Status
Accepted

---

## Context

The PetClinic system consists of two main components:

- a Spring Boot application (PetClinic)
- a PostgreSQL database

Both services need to start reliably and remain healthy during runtime. Without additional safeguards, the following issues may occur:

- application starts before the database is ready, causing connection failures
- traffic is routed to an application that is not fully initialized
- failed containers remain running without automatic recovery
- database becomes unresponsive without detection

A Kubernetes-native mechanism is required to improve startup ordering and runtime health management.

---

## Decision

A combination of **init containers** and **Kubernetes probes** is used.

### 1. Init Container (Application)

The PetClinic deployment uses an init container that waits for PostgreSQL availability:

- uses `pg_isready`
- checks connectivity to `postgres:5432`
- blocks application startup until database is ready

### 2. Readiness Probe

Both PetClinic and PostgreSQL define readiness probes:

- PetClinic: HTTP GET on `/`
- PostgreSQL: `pg_isready` command

### 3. Liveness Probe (PostgreSQL)

PostgreSQL includes a liveness probe:

- executes `pg_isready`
- restarts container if database becomes unresponsive

---

## Rationale

- Init container ensures deterministic startup ordering between database and application
- Readiness probes prevent traffic from being routed to unready services
- Liveness probes improve system resilience by restarting unhealthy containers
- Combined approach improves overall system stability without external orchestration tools
- Uses Kubernetes-native mechanisms instead of custom scripting or external supervisors

---

## Consequences

### Positive

- Prevents application failures caused by unavailable database
- Ensures only healthy and ready Pods receive traffic
- Automatic recovery from transient failures
- Improved startup predictability
- No need for external orchestration logic

### Negative

- Slightly increased startup time due to dependency waiting
- Misconfigured probes can lead to unnecessary restarts or service disruption
- Init container introduces tighter coupling between services at startup time
- No advanced health metrics beyond simple checks

---

## Alternatives Considered

### 1. No health checks
Rejected due to unstable startup behavior and lack of resilience.

### 2. External orchestration (e.g. startup scripts, CI/CD gating)
Rejected because Kubernetes-native probes provide a cleaner and more integrated solution.
