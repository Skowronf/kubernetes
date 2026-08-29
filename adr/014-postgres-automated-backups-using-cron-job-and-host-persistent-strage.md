# ADR-014: PostgreSQL Backup and Restore Architecture for Local Kubernetes GitOps Platform

## Status

Accepted

---

## Context

The PetClinic platform is deployed on a local Kubernetes cluster created with kind and follows a GitOps deployment model managed by ArgoCD.

PostgreSQL is deployed as a StatefulSet with persistent storage and serves as the primary application database.

The development environment is recreated frequently, including complete deletion and recreation of the Kubernetes cluster. Although PostgreSQL uses PersistentVolumes inside Kubernetes, storage created within the cluster is not guaranteed to survive cluster recreation when using kind.

A backup mechanism is therefore required to preserve PostgreSQL data independently of the Kubernetes cluster lifecycle.

The following requirements were identified:

- database backups must run automatically without manual intervention
- backups must survive kind cluster deletion and recreation
- backup files should be stored on the local machine filesystem
- the solution should use Kubernetes-native resources
- the backup process should be reproducible during platform bootstrap
- database restore should be possible using standard PostgreSQL tooling
- backup workloads must comply with the platform's NetworkPolicy security model

---

## Decision

A Kubernetes-native backup solution is implemented using a CronJob that periodically executes `pg_dump` and stores backup files on host-mounted persistent storage.

The backup architecture consists of:

- PostgreSQL StatefulSet
- Kubernetes CronJob
- host-mounted PersistentVolume
- PersistentVolumeClaim
- manual restore procedure
- dedicated NetworkPolicies allowing secure communication between backup workloads and PostgreSQL

---

### 1. Host-based persistent backup storage

A dedicated directory from the host machine is mounted into the kind cluster.

```
Host filesystem:
 /home/vboxuser/petclinic/backup

        |
        v

kind node:
 /host-backups

        |
        v

PersistentVolume:
 hostPath: /host-backups

        |
        v

PersistentVolumeClaim:
 postgres-backups

        |
        v

CronJob:
 /backup
```

A static PersistentVolume and PersistentVolumeClaim are used.

The PersistentVolume configuration uses:

- `hostPath` storage
- `Retain` reclaim policy
- explicit PV/PVC binding

Dynamic provisioning is disabled by configuring:

```yaml
storageClassName: ""
```

This guarantees that Kubernetes always uses the predefined host-mounted storage instead of the default StorageClass.

---

### 2. PostgreSQL backup CronJob

A Kubernetes CronJob periodically executes PostgreSQL backups using the official PostgreSQL container image.

The backup schedule is configured as:

```yaml
schedule: "0 * * * *"
```

The CronJob performs the following operations:

1. creates the backup directory if necessary
2. authenticates against PostgreSQL
3. executes `pg_dump`
4. creates a compressed PostgreSQL dump in custom format
5. updates the latest backup:

```
/backup/latest.dump
```

6. stores timestamped historical backups:

```
/backup/archive/backup-YYYY-MM-DD-HH-MM.dump
```

7. removes expired backup files according to the retention policy

---

### 3. Backup retention policy

Historical backups are automatically cleaned using:

```bash
find /backup/archive -type f -mtime +7 -delete
```

This maintains multiple recovery points while preventing unlimited local storage growth.

---

### 4. Database restore procedure

Database restore is currently performed manually using standard PostgreSQL utilities.

The recovery process consists of:

1. copying the backup file into the PostgreSQL Pod
2. terminating active database connections
3. dropping the existing database
4. recreating the database
5. restoring the dump using `pg_restore`

This procedure enables recovery after cluster recreation or accidental data loss.

---

### 5. Network security

The Kubernetes cluster follows a default-deny networking model enforced by Cilium NetworkPolicies.

Backup traffic requires both:

- egress permission from the backup workload
- ingress permission to PostgreSQL

Dedicated NetworkPolicies explicitly allow communication between the backup CronJob and PostgreSQL over TCP port 5432.

This preserves the platform's zero-trust networking model while allowing automated backups.

---

## Rationale

- Host-mounted storage allows backups to survive kind cluster deletion.
- Kubernetes CronJobs provide native scheduling without additional infrastructure.
- `pg_dump` produces portable PostgreSQL backups independent of Kubernetes resources.
- Static PersistentVolume binding provides predictable storage behavior in local development.
- Manual restore uses standard PostgreSQL tooling without requiring custom operators.
- Explicit NetworkPolicies maintain security while allowing only required database access.
- The complete solution can be deployed together with the rest of the platform using Helm and GitOps.

---

## Consequences

### Positive

- PostgreSQL data survives recreation of the kind cluster.
- Backup creation is fully automated.
- Backup storage lifecycle is independent from Kubernetes.
- Historical backups provide multiple recovery points.
- Backup files remain directly accessible from the host machine.
- Restore can be performed using standard PostgreSQL tools.
- Network communication follows least-privilege principles.
- The entire backup architecture is reproducible through Kubernetes manifests.

### Negative

- Database restore is still a manual operation.
- HostPath storage is suitable only for local development.
- Backup files exist only on a single machine.
- Frequent backups consume local disk space.
- Recovery time depends on manual execution of the restore procedure.
- Failed backups may overwrite the latest backup if atomic writes are not used.

---

## Alternatives Considered

### 1. Kubernetes PersistentVolume only

Rejected because storage managed exclusively inside the kind cluster does not guarantee persistence after cluster recreation.

---

### 2. External object storage (S3 or managed backup services)

Rejected because the project targets a local development environment and does not require external infrastructure.

---

### 3. PostgreSQL replication

Rejected because the primary objective is disaster recovery after cluster recreation rather than high availability.

---

### 4. Manual database dumps

Rejected because manual backups are unreliable and cannot be integrated into automated platform deployment.

---

## Future Improvements

- Implement automatic database restore during cluster bootstrap.
- Validate backup files before replacing the latest backup.
- Use atomic backup writes:

```bash
pg_dump > latest.dump.tmp
mv latest.dump.tmp latest.dump
```

- Validate backups before restore using:

```bash
pg_restore --list backup.dump
```

- Store PostgreSQL credentials in Kubernetes Secrets.
- Add automated restore validation tests.
- Encrypt backup files.
- Move backup storage to S3-compatible object storage for production environments.
- Implement scheduled restore testing.
- Introduce PostgreSQL WAL archiving and Point-in-Time Recovery (PITR).
- Add monitoring and alerting for failed backup jobs.
- Improve backup metrics integration with Prometheus and Grafana.