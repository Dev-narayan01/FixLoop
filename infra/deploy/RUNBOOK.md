# Operations notes (foundation)

This project is a local design preview and API foundation, not a production
service. Follow the root README to configure the server-side JDBC environment,
mount the Supabase server root certificate, and check readiness. The API uses
hostname-verified TLS and does not automatically run Flyway migrations.

The hosted database was inspected read-only: application tables existed but no
Flyway history was visible. Its analytics views also need an access review.
Do not baseline, migrate, seed, change policies, or otherwise alter Supabase
without an explicitly approved plan and appropriate backups. A connector
inspection is not proof of a working JDBC connection.

Before a hosted deployment: confirm rotation of the previously exposed database
password, review security and least-privilege database access, provision secrets
outside Git, implement authentication and authorization, configure HTTPS and
restricted CORS, and validate backups and a forward-only migration plan.

The old local Compose database service is no longer configured. Its existing
Docker volume is not removed by this change; never use volume deletion or prune
commands on data you need. Optional local tool volumes likewise persist.
