#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="petclinic"

POSTGRES_POD=$(kubectl get pods \
    -n "$NAMESPACE" \
    -l app=postgres \
    -o jsonpath="{.items[0].metadata.name}")

BACKUP_FILE="/home/vboxuser/petclinic/backup/latest.dump"

POSTGRES_USER="petclinic"
POSTGRES_DB="petclinic"

echo "Checking backup file..."

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Copying backup into PostgreSQL Pod..."

kubectl cp \
    "$BACKUP_FILE" \
    "$NAMESPACE/$POSTGRES_POD:/tmp/latest.dump"

echo "Terminating active connections..."

kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- \
psql \
-U "$POSTGRES_USER" \
-d postgres \
-c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$POSTGRES_DB'
AND pid <> pg_backend_pid();
"

echo "Dropping database..."

kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- \
dropdb \
-U "$POSTGRES_USER" \
"$POSTGRES_DB"

echo "Creating fresh database..."

kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- \
createdb \
-U "$POSTGRES_USER" \
"$POSTGRES_DB"

echo "Restoring backup..."

kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- \
pg_restore \
-U "$POSTGRES_USER" \
-d "$POSTGRES_DB" \
/tmp/latest.dump

echo "Cleaning temporary files..."

kubectl exec -n "$NAMESPACE" "$POSTGRES_POD" -- \
rm /tmp/latest.dump

echo "Restore completed successfully."