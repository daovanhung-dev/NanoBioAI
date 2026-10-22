#!/usr/bin/env bash
set -euo pipefail

: "${PGSERVICE:?Set PGSERVICE to a protected PostgreSQL service entry}"
backup_dir="${BACKUP_DIR:-/var/backups/nanobio-postgres}"
retention_days="${RETENTION_DAYS:-14}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
destination="${backup_dir}/nanobio-${timestamp}.dump"
temporary="${destination}.partial.$$"

install -d -m 0700 "${backup_dir}"
umask 077
trap 'rm -f -- "${temporary}"' EXIT
pg_dump --format=custom --no-owner --dbname="service=${PGSERVICE}" --file="${temporary}"
mv -- "${temporary}" "${destination}"
trap - EXIT
find "${backup_dir}" -type f -name 'nanobio-*.dump' -mtime "+${retention_days}" -delete
printf 'Backup written: %s\n' "${destination}"
