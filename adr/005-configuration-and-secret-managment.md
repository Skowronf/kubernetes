# ADR-005: Configuration and Secrets Management Using ConfigMap and Secret

## Status
Accepted

---

## Context

The PetClinic application requires external configuration and sensitive credentials to operate correctly, including:

- database connection configuration
- database username and password
- application-level environment variables (e.g. Spring Boot datasource settings)

Hardcoding such values inside container images would reduce flexibility and create security risks.

A Kubernetes-native mechanism is required to separate configuration and sensitive data from application code.

---

## Decision

Two Kubernetes primitives are used:

### 1. ConfigMap
Used for non-sensitive application configuration, injected into the PetClinic container via `envFrom`.

### 2. Secret
Used for sensitive data such as database credentials, also injected via `envFrom`.

Specifically:

- `ConfigMap` stores application configuration (e.g. Spring Boot settings)
- `Secret` stores:
    - `SPRING_DATASOURCE_PASSWORD`
    - `PGPASSWORD`

Both are mounted as environment variables into the application Pod.

---

## Rationale

- Separates configuration from container images, enabling environment-specific customization
- Allows configuration changes without rebuilding Docker images
- Aligns with Kubernetes best practices for configuration management
- Improves security compared to embedding credentials directly in manifests or images
- Enables consistent configuration injection via environment variables

---

## Consequences

### Positive

- Flexible runtime configuration without rebuilding images
- Clear separation between configuration and application code
- Improved security posture compared to hardcoded credentials
- Kubernetes-native approach with built-in primitives

### Negative

- Secrets are only base64-encoded in Kubernetes (not encrypted by default)
- Risk of accidental exposure via misconfigured RBAC or logs
- No external secret management system (e.g. Vault, Sealed Secrets)
- Environment variable injection can lead to credential exposure in process listings

---

## Alternatives Considered

### 1. Hardcoding configuration in Docker image
Rejected due to lack of flexibility and poor security practices.

### 2. External secret management system (e.g. HashiCorp Vault)
Rejected due to increased operational complexity not required for current scope.

### 3. Mounted configuration files instead of environment variables
Rejected for simplicity; env-based configuration aligns better with Spring Boot defaults.
