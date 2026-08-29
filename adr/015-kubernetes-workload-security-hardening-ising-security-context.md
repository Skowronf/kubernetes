# ADR-015: Kubernetes Workload Security Hardening Using SecurityContext

## Status
Accepted

---

## Context

The PetClinic application is deployed on Kubernetes using Argo Rollouts for progressive delivery.

Initially, the application container was running without explicit runtime security restrictions. The Docker image was based on `eclipse-temurin:17-jre` and did not define a dedicated non-root application user.

By default, containers may run with root privileges depending on the image configuration. Running application workloads as root increases the potential impact of application vulnerabilities because a compromised process may have unnecessary permissions inside the container.

The platform requires application workloads to follow the principle of least privilege and Kubernetes security best practices.

The following security requirements were identified:

- application containers must not run as root
- container runtime user must be explicitly defined
- privilege escalation must be disabled
- unnecessary Linux capabilities must be removed
- container filesystem should be immutable during runtime
- application must still have access to required writable locations
- security configuration must be inherited by all Argo Rollouts ReplicaSets (stable and canary)

---

## Decision

The PetClinic container image and Kubernetes Rollout configuration are hardened using Linux user separation and Kubernetes `securityContext`.

The security implementation is divided into two layers:

1. Container image security
2. Kubernetes runtime security

---

## 1. Non-root application user in container image

A dedicated application user is created during Docker image build.

The image creates:

    User:
      appuser

    UID:
      10001

    Group:
      appgroup

    GID:
      30001

The application directory ownership is changed to the application user:

    RUN groupadd -g 30001 appgroup && \
        useradd -u 10001 -g 30001 -m appuser && \
        chown -R appuser:appgroup /app

The Java process is started as the non-root user:

    USER appuser

This ensures that the container does not require root privileges to run the application.

---

## 2. Kubernetes Pod securityContext

The Argo Rollout Pod template defines security restrictions inherited by all created Pods.

The following configuration was added:

    securityContext:
      runAsNonRoot: true
      runAsUser: 10001
      runAsGroup: 30001
      fsGroup: 20001

The configuration provides:

### runAsNonRoot

Prevents the container from starting with root privileges.

### runAsUser

Forces the application process to run with the dedicated application UID.

### runAsGroup

Defines the primary process group.

### fsGroup

Allows non-root processes to access mounted volumes.

---

## 3. Container security restrictions

Additional container-level security settings were applied:

    securityContext:
      allowPrivilegeEscalation: false

      capabilities:
        drop:
          - ALL

      readOnlyRootFilesystem: true

The configuration provides:

### Disabled privilege escalation

The container process cannot gain additional privileges during runtime.

### Removed Linux capabilities

All unnecessary Linux capabilities are removed.

The application runs without additional kernel permissions.

### Read-only root filesystem

The container filesystem becomes immutable after startup.

Application binaries and system files cannot be modified during runtime.

---

## 4. Writable temporary filesystem

Spring Boot applications require temporary filesystem access, mainly through `/tmp`.

Because the container root filesystem is read-only, a dedicated temporary volume is mounted:

    volumes:
      - name: tmp
        emptyDir: {}

Mounted into the application container:

    volumeMounts:
      - name: tmp
        mountPath: /tmp

This keeps the main filesystem protected while allowing required runtime operations.

---

## Validation

The implementation was validated using Kubernetes runtime checks.

### Verify non-root execution

Command:

    kubectl exec -n petclinic <pod-name> -- id

Expected result:

    uid=10001
    gid=30001

The application process is not running as UID `0`.

---

### Verify read-only root filesystem

Command:

    kubectl exec -n petclinic <pod-name> -- touch /test-file

Expected result:

    Read-only file system

The container filesystem cannot be modified.

---

### Verify writable temporary directory

Command:

    kubectl exec -n petclinic <pod-name> -- touch /tmp/test-file

Expected result:

The command succeeds because `/tmp` is provided through a writable `emptyDir` volume.

Made sure with command

Command:

    kubectl exec -n petclinic <pod-name>  -- ls -la /tmp


---

## Rationale

- Running containers as non-root reduces the impact of potential application vulnerabilities
- Kubernetes-level enforcement prevents accidental insecure container execution
- Removing Linux capabilities follows the principle of least privilege
- Read-only filesystem prevents runtime modification of application files
- Separating writable directories reduces the possible attack surface
- Applying securityContext at the Rollout Pod template level ensures that both stable and canary ReplicaSets use identical security settings
- The solution is compatible with Argo Rollouts progressive delivery strategy

---

## Consequences

### Positive

- PetClinic application no longer runs with root privileges
- Container compromise has a reduced security impact
- Kubernetes actively prevents insecure runtime configuration
- Application filesystem is protected against modification
- Security configuration is automatically applied to new Rollout revisions
- The workload follows Kubernetes container security best practices
- Security settings are version-controlled together with application deployment configuration

---

### Negative

- Images must be designed to support non-root execution
- Some applications may require additional writable volumes
- Debugging filesystem permission issues becomes more complex
- Third-party images may require additional adjustments before they can run securely
- InitContainers may require separate security hardening

---

## Alternatives Considered

### 1. Running the application container as root

Rejected because:

- increases security risk
- violates least privilege principles
- increases potential impact of container compromise

---

### 2. Only configuring Kubernetes runAsUser

Rejected because:

- container image would still be designed to run with root privileges
- security responsibility would exist only at runtime level
- image would not be portable between environments

---

### 3. Leaving the root filesystem writable

Rejected because:

- compromised processes could modify application files
- attackers could persist malicious changes inside the container filesystem

---

### 4. Using a privileged container

Rejected because:

- not required for Spring Boot application workload
- introduces unnecessary permissions and security risk

---

## Future Improvements

- Apply equivalent securityContext restrictions to initContainers
- Replace PostgreSQL initContainer image with a minimal non-root PostgreSQL client image
- Add Kubernetes Pod Security Admission policies
- Add automated security checks during CI pipeline
- Integrate container security scanning results into deployment decisions
- Add Kyverno or Gatekeeper policies enforcing non-root containers across namespaces