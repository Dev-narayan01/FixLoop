# Track C — platform and quality: the specific version

Everything below is a fact in the repository, and each row names how to show it.

## 0. One sentence

Track C owns the runnable API (Java 21, Spring Boot 3.5.16, Maven), its security layer, its
test evidence, and the path from a laptop to a real PostgreSQL 17 database on Supabase.

## 1. What exists, concretely

### API surface — 12 documented endpoints (`docs/openapi/openapi.yaml`)

| Group | Endpoints |
|---|---|
| Health | `GET /api/v1/health`, `GET /actuator/health` |
| Identity | `POST /auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`, `/auth/change-password`, `GET /me` |
| Attachments | `POST /api/v1/attachments` |
| Notifications | `GET /api/v1/notifications`, `POST /notifications/{id}/read`, `POST /notifications/read-all` |

The contract is the interface the mobile track codes against, so it is written before the
client, not after.

### Identity rules — each one is a test, not an intention

- **Registration is restricted to `bmu.edu.in`** addresses via `ALLOWED_EMAIL_DOMAINS`, so the
  campus-only premise is enforced in code rather than in a policy document.
- **Passwords**: minimum 12 characters, BCrypt's 72-byte ceiling enforced explicitly (BCrypt
  silently truncates beyond it, which would make two different passwords equivalent), a
  seven-entry common-password blocklist, and rejection of the user's own email or its local
  part as the password.
- **Tokens**: HS256-signed JWTs, `iss` is a URI (`https://fixloop.local`), access token 15
  minutes, refresh token 14 days and **rotated on every use**. Sessions are stateless — no
  server-side session, no CSRF token needed because nothing rides on a cookie.
- **Failures are JSON, not HTML**: a custom `AuthenticationEntryPoint` returns the same error
  shape as the rest of the API, which is what a mobile client can actually parse.
- **Seven rate limits**, in-process, keyed by route and identity:

| Route | Limit |
|---|---|
| register | 5 / hour |
| login | 10 / 5 min |
| refresh | 60 / 5 min |
| logout | 60 / 5 min |
| change-password | 10 / hour |
| attachment upload | 30 / 5 min |
| notification reads | 120 / 5 min |

Known limitation, stated in the checklist: the limiter is in memory, so it is correct for one
instance and would need Redis if the API were ever scaled out.

### Uploads — content-first, because the client can lie

`AttachmentPolicy.inspect()` reads the bytes and detects JPEG, PNG or WebP by signature; the
declared `Content-Type` is only cross-checked and a mismatch is rejected. An empty file is
400, over the 8 MiB cap is 413, a non-photograph is 415. Stored files get a generated name and
a SHA-256 checksum, and a failing disk write returns a clean error rather than a stack trace —
`AttachmentServiceTest.reportsAFriendlyFailureWhenTheDiskRefusesTheWrite` asserts exactly that.

### Notifications — built on the outbox table that already existed

`IN_APP` rows are written `SENT`; `EMAIL` and `PUSH` rows are written `PENDING` and nothing
drains them yet, because there are no mail or push credentials. Type is capped at 60
characters, payload at 4096 bytes, list size defaults to 50 and is bounded at 100. `markRead`
is idempotent, another user's notification id returns 404 rather than 403 (a 403 would confirm
the row exists), and every query is scoped by `user_id`.

### Database

Thirteen tables in `V1__init.sql` — `departments`, `locations`, `users`, `categories`,
`status_transitions`, `routing_rules`, `sla_policies`, `settings`, `complaints`,
`complaint_events`, `attachments`, `notifications_outbox`, `refresh_tokens` — 107 columns.
A parse of the file was compared against the hosted database column by column and matched.
`V2__attachments_checksum.sql` adds the nullable `attachments.checksum_sha256`; it is
forward-only because V1 is already applied and is never edited.

`DatabaseConnectionSafety` refuses to start if the database connection does not use
`sslmode=verify-full`, which is why the CA certificate path is part of `.env`.

## 2. Evidence

| Claim | How to show it |
|---|---|
| 57 unit tests pass | `mvn -B -ntp -f apps/api/pom.xml test` → `Tests run: 57, Failures: 0, Errors: 0` |
| The artefact is deployable | `mvn -DskipTests package` → `apps/api/target/fixloop-api-0.1.0-SNAPSHOT.jar` |
| Tests are distributed sensibly | 5 auth-security, 3 JWT, 7 password policy, 4 health, 4 rate limiter, 2 auth properties, 3 database safety, 1 database defaults, 5 notification security, 9 notification service, 2 attachment security, 6 attachment policy, 3 attachment service, 3 filesystem storage |
| The database path is checkable | `bash infra/deploy/db-check.sh` — 27 assertions: config, CA certificate is real PEM, TLS, schema, no plaintext credentials |
| Recovery is planned, not hoped for | `bash infra/deploy/backup-drill.sh` — dump the hosted database, restore into a throwaway container, compare |
| Someone else could run it | `infra/deploy/RUNBOOK.md`, `infra/deploy/preflight.sh` |
| Decisions are recorded | `docs/adr/ADR-001-modular-monolith.md`, `ADR-002-spring-boot.md`, `ADR-003-local-and-hosted-databases.md` |
| Honesty is tracked | `docs/quality/security-checklist.md` — 52 items: 27 done, 6 unverified, 16 open, 3 not applicable |

## 3. What is not proven — the exact state

1. **Two integration classes, ten methods, do not run here.** `AuthFlowIT` and
   `DatabaseMigrationIT` need Docker; Docker is absent from the WSL distribution, so Maven
   fails with `Could not find a valid Docker environment` before any assertion executes.
   Not a pass, not a failure — no result.
2. **`db-check.sh` has never reached its summary line.** First run: the four database
   variables were unset. Second run: `DATABASE_URL` still held the template's `<host>`, which
   the shell earlier reported as `line 5: host: No such file or directory`. Both faults are
   now reported by name by the script itself.
3. **No production code raises a notification yet.** The inbox is complete and tested; the
   caller does not exist. That is a deliberate boundary, not an omission.
4. **Synthetic data (G4) is empty.** `data/synthetic/generate.py` and
   `routing_test_set.csv` exist as zero-byte placeholders. Due 20 Nov.

## 4. Next, in order

1. Fill the real database host; expect `db-check.sh` to end with 0 failures.
2. Enable Docker's WSL integration; the two integration classes then run in `mvn verify`.
3. One recorded backup-restore drill.
4. The synthetic-data generator, then wiring notifications into the complaint workflow.

## 5. Answers to the questions that will be asked

**"Why a monolith?"** ADR-001: one team, one deadline, one deployment. Service boundaries
inside the code give the same discipline without the operational cost of a network between
them.

**"Why does a complaint system need rate limits?"** Registration is restricted to one email
domain, so an attacker's cheapest move is password guessing against known accounts. Ten login
attempts per five minutes per identity makes that impractical without harming a real user.

**"What happens if the database goes away?"** The API fails health checks rather than serving
inconsistent data, and the runbook's restore path is the backup drill — which is written and
has to be run once, end to end, before I claim it works.

**"What is the risk to the 28 Nov deadline?"** The only unverified item with schedule risk is
the integration suite, and its blocker is a local Docker setting, not code. The synthetic data
is the real work left.

**"What would you do differently?"** Verification was batched behind the environment instead
of being proven on the first day the database existed. The checklist now records 'unverified'
separately from 'done' precisely so that gap cannot hide again.
