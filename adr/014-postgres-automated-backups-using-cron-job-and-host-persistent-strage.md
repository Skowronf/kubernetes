# ADR-014: PostgreSQL Automated Backups Using Kubernetes CronJob and Host Persistent Storage

## Status
Accepted

---

## Context

The PetClinic platform uses PostgreSQL as the primary database. The development environment is deployed on a local Kubernetes cluster created with kind.

The cluster lifecycle includes frequent recreation of the whole environment, which can result in database data loss because Kubernetes resources and storage created inside the cluster may not survive cluster deletion.

A mechanism is required to preserve PostgreSQL data independently from the Kubernetes cluster lifecycle.

The following requirements were identified:

- database backups must run automatically without manual intervention
- backups must survive kind cluster deletion and recreation
- backup files should be stored on the local machine filesystem
- the solution should use Kubernetes-native resources
- the backup process should be reproducible during platform bootstrap

---

## Decision

A Kubernetes CronJob is used to periodically create PostgreSQL backups using `pg_dump`.

The backup solution consists of a host-mounted persistent storage volume and an automated backup job.

---

### 1. Host-based persistent backup storage

A dedicated directory from the host machine is mounted into the kind cluster:

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
- explicit PV and PVC binding

Dynamic provisioning is disabled for the backup volume by setting:

```yaml
storageClassName: ""
```

This ensures that Kubernetes uses the predefined host-based volume instead of the default cluster StorageClass.

---

### 2. PostgreSQL backup CronJob

A Kubernetes CronJob runs periodically and executes PostgreSQL backup commands.

The backup schedule is:

```yaml
schedule: "*/5 * * * *"
```

The CronJob uses the PostgreSQL image and runs `pg_dump` against the PostgreSQL service.

The backup process performs the following steps:

1. creates the backup directory if it does not exist
2. authenticates against PostgreSQL
3. creates a compressed PostgreSQL dump using custom format
4. stores the latest backup:

```
/backup/latest.dump
```

5. creates timestamped historical backups:

```
/backup/archive/backup-YYYY-MM-DD-HH-MM.dump
```

6. removes backups older than two days

---

### 3. Backup retention policy

Historical backups are automatically cleaned using:

```bash
find /backup/archive -type f -mtime +7 -delete
```

This keeps recent recovery points while preventing unlimited disk usage.

---

## Rationale

- Host-based storage allows backup files to survive kind cluster deletion
- Kubernetes CronJob provides native scheduling without external backup tooling
- `pg_dump` creates portable PostgreSQL backups independent from the running cluster
- Static PV binding provides predictable behavior in a local development environment
- The solution can be deployed together with the rest of the platform using Helm
- Backup files remain accessible directly from the developer machine

---

## Consequences

### Positive

- PostgreSQL data can be preserved after kind cluster recreation
- Backup creation is fully automated
- Backup storage lifecycle is independent from Kubernetes cluster lifecycle
- Historical backups provide multiple recovery points
- No external backup infrastructure is required
- The solution is reproducible through Kubernetes manifests

### Negative

- Automatic database restore during cluster bootstrap is not implemented yet
- HostPath storage is suitable only for local development environments
- Backup files exist only on a single machine
- Frequent backups increase local storage usage
- Database recovery currently requires a manual restore process

---

## Alternatives Considered

### 1. Kubernetes PersistentVolume only

Rejected because cluster-managed storage does not guarantee data preservation after deleting and recreating a kind cluster.

---

### 2. External backup storage (S3, managed database backups)

Rejected because the current environment is local development based on kind and does not require external infrastructure.

---

### 3. PostgreSQL replication

Rejected because the main requirement is disaster recovery after cluster recreation, not high availability.

---

### 4. Manual database dumps

Rejected because manual backups are unreliable and do not integrate with automated platform bootstrap.

---

## Future Improvements

- Add automated PostgreSQL restore during initial cluster bootstrap
- Add backup restore validation
- Store PostgreSQL credentials using Kubernetes Secrets
- Move backup storage to external object storage for production environments