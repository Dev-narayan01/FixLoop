# Security checklist — G4 (Fri 20 Nov)

Status legend:

- **DONE** — implemented and checked, with a command or test that proves it
- **UNVERIFIED** — implemented, but not yet exercised in a real environment
- **OPEN** — not done yet; needs a fix or an accepted-risk line in the report
- **N/A** — out of scope, stated deliberately

At G4 every **OPEN** row must become **DONE**, or be written into the report as an
accepted risk with a reason. An unexamined checkbox is worse than an honest gap.

Owner column: **D** = Dev (Track C), **Y** = Yash, **Du** = Dushyant.

## 1. Secrets and credentials

| # | Item | Status | Evidence / next step | Owner |
|---|---|---|---|---|
| 1.1 | No secrets in the working tree | **DONE** | `git ls-files \| grep -E '^\.env$\|^secrets/'` prints nothing (`.gitignore` lines 2, 10) | D |
| 1.2 | Leaked database password rotated and old value dead | **OPEN** | README §*Important*; rotate in Supabase → Database Settings, update `.env`, tell Y and Du | D + Du |
| 1.3 | `JWT_SECRET` is ≥32 random bytes, not a placeholder | **UNVERIFIED** | `bash infra/deploy/preflight.sh` on the real deployment config | D |
| 1.4 | No credentials inside the JDBC URL | **DONE** | `DatabaseConnectionSafety` + `DatabaseConnectionSafetyTest` | Y (code), D (review) |
| 1.5 | Tooling never prints secrets | **DONE** | `preflight.sh`, `db-check.sh` mask password and URL | D |

## 2. Transport

| # | Item | Status | Evidence / next step | Owner |
|---|---|---|---|---|
| 2.1 | Database connection uses `sslmode=verify-full` | **DONE** | `application.yml` (`sslmode`, `sslrootcert`); safety bean refuses anything else | Y |
| 2.2 | TLS actually verified against Supabase from our host | **UNVERIFIED** | run `bash infra/deploy/db-check.sh`; expect "session is encrypted" | D |
| 2.3 | Public API served over HTTPS only | **OPEN** | blocked on D4 hosting choice; Render provides TLS, so it is a config check, not code | D |
| 2.4 | HSTS and security headers on the public origin | **OPEN** | Spring's defaults are on; add HSTS at the host once a domain exists | D |
| 2.5 | CORS restricted to known origins | **DONE** | `SecurityConfiguration#corsConfigurationSource`; preflight fails on `*` | D |

## 3. Authentication

| # | Item | Status | Evidence / next step | Owner |
|---|---|---|---|---|
| 3.1 | Own tokens: HS256, 15-minute access, minimal claims, no email | **DONE** | `JwtService`, `JwtServiceTest` | D |
| 3.2 | Refresh tokens: 14 days, SHA-256 hashed, single use, replay revokes all | **DONE** | `AuthService#refresh`, `AuthFlowIT`, smoke steps 12–19 | D |
| 3.3 | BCrypt cost 12, 12-char minimum, email-as-password rejected | **DONE** | `PasswordPolicy`, `PasswordPolicyTest` | D |
| 3.4 | Login failures indistinguishable | **DONE** | `AuthControllerSecurityTest` | D |
| 3.5 | Rate limits on register/login/refresh/logout/password/upload | **DONE** | `RequestRateLimiterTest`; limits in `AuthController` | D |
| 3.6 | Rate limiter survives more than one instance | **N/A** | single instance; documented limitation | D |
| 3.7 | Multi-factor authentication | **N/A** | out of scope for the project; state it in the report | D |

## 4. Authorisation

| # | Item | Status | Evidence / next step | Owner |
|---|---|---|---|---|
| 4.1 | Deny-by-default: unlisted URLs are closed | **DONE** | `SecurityConfiguration#securityFilterChain`, `anyRequest().denyAll()` | D |
| 4.2 | 401 and 403 distinguishable, both JSON with `traceId` | **DONE** | `writeError`, `AuthControllerSecurityTest` | D |
| 4.3 | Role checks on staff/supervisor actions | **OPEN** | not built yet; arrives with the workflow endpoints | Du |
| 4.4 | Attachment download authorised against the complaint | **OPEN** | endpoint deliberately absent until complaints exist | D |
| 4.5 | Row-level security decided for the hosted database | **OPEN** | three public views with anonymous SELECT; run the RLS queries in the SQL editor | D + Du |

## 5. Input handling and uploads

| # | Item | Status | Evidence / next step | Owner |
|---|---|---|---|---|
| 5.1 | Request bodies validated, one error shape with field details | **DONE** | `ApiExceptionHandler`, `ApiError` | D |
| 5.2 | Uploads identified by magic bytes, not name or header | **DONE** | `ImageType#detect`, `AttachmentPolicyTest` | D |
| 5.3 | Declared type contradicting content refused (415) | **DONE** | `AttachmentPolicyTest` | D |
| 5.4 | Size limits enforced with a JSON 413 | **DONE** | policy 8 MiB, multipart 10/12 MB, `MaxUploadSizeExceededException` handler | D |
| 5.5 | Path traversal impossible | **DONE** | key shape regex + `normalize()` in `FilesystemStorage` | D |
| 5.6 | No SQL built by string concatenation of user input | **DONE** | all queries are `JdbcTemplate` placeholders; review with `grep -rn 'jdbc\.\(query\|update\)' apps/api/src/main` | D |
| 5.7 | Duplicate complaint submission prevented (idempotency key) | **OPEN** | `complaints.idempotency_key` exists, nothing writes it | Du |

## 6. Errors, logging and privacy

| # | Item | Status | Evidence / next step | Owner |
|---|---|---|---|---|
| 6.1 | No stack traces or internal messages to clients | **DONE** | `server.error.include-*: never`; handler returns codes only | D |
| 6.2 | Every error carries a `traceId` for correlation | **DONE** | `TraceIdFilter`, exposed as a response header | D |
| 6.3 | Logs contain no passwords, tokens, hashes or file contents | **UNVERIFIED** | grep the log statements before go-live; audit log is not enabled yet | D |
| 6.4 | Access log with method, status and latency | **OPEN** | not configured; the host may provide one | D |
| 6.5 | Retention and deletion rules agreed | **OPEN** | bible Q10 (semester 2) — record as accepted risk for this project | Du |

## 7. Dependencies and build

| # | Item | Status | Evidence / next step | Owner |
|---|---|---|---|---|
| 7.1 | Dependency versions pinned | **DONE** | `apps/api/pom.xml`, `pubspec.yaml` locks | Y |
| 7.2 | Automated dependency or container scanning | **OPEN** | no Dependabot, no OWASP dependency-check in CI; add Dependabot (free) | D |
| 7.3 | Container runs as non-root | **DONE** | `Dockerfile`: `USER fixloop` (uid 10001) | Y |
| 7.4 | Base images reviewed before freeze | **OPEN** | `maven:3.9.11-eclipse-temurin-21`, `eclipse-temurin:21-jre-jammy` — check for updates at G4 | Y |

## 8. Operations

| # | Item | Status | Evidence / next step | Owner |
|---|---|---|---|---|
| 8.1 | Pre-deploy configuration check | **DONE** | `infra/deploy/preflight.sh`, exercised against six synthetic configs | D |
| 8.2 | Database reachability and schema check | **DONE** (script) / **UNVERIFIED** (against Supabase) | `infra/deploy/db-check.sh` | D |
| 8.3 | Health endpoint for liveness and DB readiness | **DONE** | `/api/v1/health`, `/actuator/health` (includes a `db` indicator) | Y |
| 8.4 | Backup exists and a restore has been tested | **OPEN** | `infra/deploy/backup-drill.sh`; free tier has no automatic backups, so the dump *is* the backup | D |
| 8.5 | Rollback plan written and exercised | **UNVERIFIED** | RUNBOOK §Rollback; must be read once against a real deploy | D |
| 8.6 | Free-tier project pause risk handled | **OPEN** | weekly dashboard visit until the demo, or accept the risk in writing | D |
| 8.7 | Monitoring and alerting | **OPEN** | none beyond the host's health check; state it as a limitation | D |

## 9. What "ticked" means at G4

For each row, be able to say one of:

- **"Done, and here is the command"** — run it in front of the reviewer if asked.
- **"Not done, here is why, and here is what it would cost"** — written in the report's
  limitations section.

The three rows most likely to be asked about in a viva are 1.2 (the exposed
password), 4.5 (RLS on the hosted database) and 8.4 (an untested backup). Have the
answer ready for each one.
