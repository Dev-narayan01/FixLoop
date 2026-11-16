# Track C: what "complete" means here

A project is not complete because there is nothing left to do. It is complete when the scope is
stated, every item in that scope has evidence, and the items outside it are named with a date.
This page is that statement, so a reader can check it instead of trusting a summary.

## 1. The scope, as declared

Track C covers the platform a campus complaint system needs to run and be trusted:

1. a runnable HTTP API with a published contract;
2. identity and session handling that a mobile client can rely on;
3. safe handling of the photographs complaints carry;
4. the notification path a complaint system needs after a status change;
5. automated tests for all of it;
6. a way to reach a real database, check it, and recover it;
7. the written decisions, runbook and security checklist that make the above reviewable.

Everything else in the repository — complaints, routing, workflow, the Flutter app — belongs to
the other two tracks and is out of scope for this statement.

## 2. Definition of done, item by item

| # | Deliverable | Evidence | Status |
|---|---|---|---|
| 1 | 12 endpoints on one OpenAPI contract | `docs/openapi/openapi.yaml`; compile | **done** |
| 2 | Register, login, refresh, logout, change-password, /me | `AuthService`, `AuthController`; 5 security tests + 3 JWT tests | **done** |
| 3 | Password rules enforced, not documented | `PasswordPolicy` — 12 characters, 72-byte ceiling, blocklist; 7 tests | **done** |
| 4 | JSON errors, never an HTML error page | `ApiExceptionHandler`, custom `AuthenticationEntryPoint`; asserted in tests | **done** |
| 5 | Seven rate limits on the routes that matter | `AuthController`, `AttachmentController`, `NotificationController`; 4 tests | **done** |
| 6 | Photograph uploads validated by content | `AttachmentPolicy` (JPEG/PNG/WebP by signature, 8 MiB); 6 tests | **done** |
| 7 | Stored files named by the server, checksummed | `FilesystemStorage`, `attachments.checksum_sha256`; 3 + 3 tests | **done** |
| 8 | In-app notification inbox, user-scoped | `NotificationService`, `NotificationController`; 9 + 5 tests | **done** |
| 9 | 57 automated tests, green | `mvn -f apps/api/pom.xml test` → `Tests run: 57, Failures: 0, Errors: 0` | **done** |
| 10 | Deployable artefact | `fixloop-api-0.1.0-SNAPSHOT.jar`, repackaged by Spring Boot | **done** |
| 11 | Schema in version control, forward-only | `V1__init.sql` (13 tables, 107 columns), `V2__attachments_checksum.sql` | **done** |
| 12 | Schema equals the hosted database | column-by-column comparison, 0 differences, recorded | **done** |
| 13 | Connection cannot run without verified TLS | `DatabaseConnectionSafety` rejects anything but `sslmode=verify-full`; 3 tests | **done** |
| 14 | Database reachability check | `infra/deploy/db-check.sh`, 27 assertions | **written, never green** |
| 15 | Backup and restore drill | `infra/deploy/backup-drill.sh` | **written, never run** |
| 16 | Configuration check + runbook | `infra/deploy/preflight.sh`, `RUNBOOK.md` | **done** |
| 17 | Decisions recorded | `ADR-001`, `ADR-002`, `ADR-003` | **done** |
| 18 | Security posture stated honestly | `docs/quality/security-checklist.md` — 52 items: 27 done, 6 unverified, 16 open, 3 N/A | **done** |
| 19 | Integration tests (ten methods) run somewhere | `AuthFlowIT`, `DatabaseMigrationIT`; CI workflow written | **written, never executed** |
| 20 | Synthetic data for routing evaluation (G4) | `data/synthetic/` — empty placeholders | **not started, due 20 Nov** |

Rows 14, 15, 19 and 20 are the only ones outside "done". They are dated and owned, and each has
a blocker that is written down: a configuration value, a Docker setting, and an unstarted file
respectively.

## 3. The completeness claim, in one sentence

> Track C's application layer — contract, identity, uploads, notifications, tests, artefact and
> design record — is complete and demonstrable. The evidence that it runs against real
> infrastructure is four dated items, and I can name each one, its blocker, and its next action.

Every word of that is checkable. Nothing in it is a promise dressed as a result.

## 4. Four claims that must never be made

1. **"CI is green."** The workflow is written and has never run; fork workflows await approval
   from the base repository's owner, so the pull request shows zero checks.
2. **"The integration tests pass."** They do not run. There is no result, not a passing one.
3. **"The database check passes."** It has never reached its summary line.
4. **"The deployed system is live."** No hosting decision has been executed; there is a jar, not
   a running service.

Each of these is a sentence a reader can disprove in one command, which is why saying it would
cost more than admitting the gap.

## 5. The fastest path to a live demonstration

A running server beats any table. This is the shortest route, and it does not need Docker:

```bash
cd "/mnt/c/Users/DEV NARAYAN/Downloads/PRJ1/FixLoop"
git pull --ff-only
# put the real host, user, password and CA certificate path in .env, then:
bash infra/deploy/db-check.sh          # this must end with 0 failed first
mvn -f apps/api/pom.xml spring-boot:run
```

In a second terminal, the whole slice in five commands:

```bash
curl -s localhost:8080/api/v1/health
curl -s -X POST localhost:8080/api/v1/auth/register -H 'Content-Type: application/json' \
  -d '{"email":"dev.narayan.24cse@bmu.edu.in","password":"a long passphrase","fullName":"Dev Narayan"}'
curl -s -X POST localhost:8080/api/v1/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"dev.narayan.24cse@bmu.edu.in","password":"a long passphrase"}'
TOKEN=<accessToken from the previous response>
curl -s localhost:8080/api/v1/me -H "Authorization: Bearer $TOKEN"
curl -s localhost:8080/api/v1/notifications -H "Authorization: Bearer $TOKEN"
curl -s -i localhost:8080/api/v1/me                       # expect 401 as JSON, not HTML
```

That sequence proves identity, persistence, authorisation and the notification inbox against a
real database in under a minute — which is what "complete" actually means to a reader.

## 6. If it cannot be live today

Show, in this order, and nothing else:

1. `mvn -B -ntp -f apps/api/pom.xml test | tail -5` — the 57.
2. `docs/openapi/openapi.yaml` — the contract the mobile track codes against.
3. `docs/quality/security-checklist.md` — 27 done, 6 unverified, 16 open, 3 N/A.

Then say the sentence from section 3 and stop talking. A stated boundary is a finished thought;
a list of excuses is not.
