# AI usage log

| Date (UTC) | Who / tool | Assistance | Human review and follow-up |
|---|---|---|---|
| 2026-10-28 | Arena.ai coding agent, at the repository owner's request | Reviewed the supplied v0.2 project bible and existing repository; drafted the local Docker setup, Spring Boot foundation, security defaults, tests, Flutter placeholder and documentation. Preserved the existing SQL migration; removed the tracked config containing an apparent database credential. | Team review and teach-back are still required. Rotate the exposed credential with the project owner; removing it from the current tree does not remove it from Git history. No Supabase connection was made. |
| 2026-11-02 | Arena.ai coding agent, at the repository owner's request | Read the supplied Stitch design and drafted a Flutter-only preview and server-side, TLS-verified Supabase JDBC configuration. Removed the local database service from the default Compose file without deleting its volume; kept Flyway disabled for the hosted schema. | Human review, local Flutter/Java checks and a real JDBC connection check with locally supplied credentials and CA are required. No hosted schema or policies were changed. Authentication and real reports remain unimplemented. |

Automated verification: the original migration and sample seed were checked on a
disposable PostgreSQL 16 instance, and the initial GitHub Actions run passed the
Java, Docker and Flutter checks. A teammate still needs to review the changes
and run the setup on their own computer.

Do not merge AI-generated changes unread. Record subsequent human changes and
verification here in accordance with the project bible.
