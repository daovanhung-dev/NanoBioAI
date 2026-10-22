# Ubuntu Operations

Install PostgreSQL as a native Ubuntu service. Create a dedicated database and least-privilege backend role. Run migrations as a controlled release step, then run the API under a dedicated systemd user with a root-owned `EnvironmentFile` (`0600`) or secret store. Keep upload storage outside the source tree and restrict filesystem permissions. Configure reverse proxy TLS, allowed origins, request size limits and firewall separately.

Use `/health/live` for process health and `/health/ready` for PostgreSQL readiness. Back up with `pg_dump` plus protected storage backup, encrypt off-host copies, retain according to policy, and periodically verify restore on an isolated host. This repository phase documents but does not execute server deployment or backup.
