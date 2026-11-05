# Chapter — Track C: platform and quality

Draft for the project report. Written to be pasted into the report and edited; the
figures and file paths are current at the date of writing (5 November 2026).

---

## 1. Scope and ownership

The project was divided by track. Track C covers the platform and the quality of
the whole system rather than a single feature: the API foundation, authentication
and authorisation, file storage for evidence photographs, the database
environment, deployment tooling, and the testing and security position that the
other two tracks depend on.

Delivered in this track: the identity slice (D7), the attachment upload slice, the
deployment runbook with two pre-deployment checks, and the architecture decision
records. Not delivered here, because it belongs to other tracks: complaint
creation and routing (Track A), and the Flutter client (Track B).

## 2. Requirements traceability

| Source | Requirement | Where it is met |
|---|---|---|
| Bible D7 | Own email and password authentication, JWT access token, rotating refresh token, staff accounts created by an administrator | `auth/` package; the administrator-created accounts are **not** yet implemented |
| Bible G1 | A deployed API health endpoint, migrations applied, register and login working against the deployed API | Health endpoint exists; **no deployment yet**, so G1 is unmet |
| Bible G2–G4 | Photo evidence on complaint creation; a tested, frozen system at G4 | Upload endpoint done; the rest depends on the complaint endpoints |
| Bible FR-105 / 106 / 107 | Email confirmation, admin-created staff accounts, password reset | **Not implemented**; all three need a mail transport |
| NFR: zero budget (D5) | No paid tier, no card | Free-tier Supabase; hosting decision still open (D4) |

The traceability table is deliberately blunt: two rows are unmet and are visible
here rather than discovered at the demonstration.

## 3. Architecture and design decisions

Three decisions were recorded as ADRs rather than settled in conversation, because
each one is expensive to reverse:

- **ADR-001, modular monolith.** One Spring Boot application with package-level
  modules (`auth`, `storage`, `common`, `config`) instead of separate services.
  With three developers and a six-week window, a distributed system would spend its
  budget on plumbing.
- **ADR-002, Spring Boot as the backend.** Chosen for the platform's built-in
  security, JDBC and testing support, and because the team already knew it. The cost
  is JVM memory on a free tier.
- **ADR-003, local and hosted databases.** *Proposed, not yet accepted.* The hosted
  database requires TLS and has Flyway disabled; a plain local PostgreSQL therefore
  cannot be used with the current configuration. The ADR proposes a named `local`
  profile (TLS off, Flyway on, nothing else changed) so that both paths can be
  exercised. This is the clearest example in the project of a security decision
  creating friction that has to be designed for rather than ignored.

The authentication design is documented in section 4.1. The reasoning in one line:
the access token is stateless and therefore cannot be revoked, so it is short-lived;
the refresh token is stateful and revocable, so it can carry the long lifetime.

Two constraints were written into code rather than into documentation, because
documentation is not enforcement:

- **`DatabaseConnectionSafety`** refuses to start the API when the JDBC URL contains
  credentials or a query string, when TLS is not `verify-full`, or when Flyway is
  enabled. Configuration mistakes that would silently weaken the system become
  startup failures.
- **`SecurityConfiguration`** ends with `anyRequest().denyAll()`. A new endpoint is
  unreachable until someone names it, so the failure mode of forgetting is "closed",
  not "open".

## 4. Implementation

### 4.1 Identity

Seven endpoints: register, login, refresh, logout, change password, and the caller's
own account. Mechanisms:

| Concern | Mechanism |
|---|---|
| Access token | JWT, HS256, 15-minute lifetime, claims limited to user id, role, department and location scope — never the email address |
| Refresh token | 32 random bytes from `SecureRandom`, 14 days, stored only as a SHA-256 hash, single use |
| Replay detection | Presenting an already-rotated token revokes every session for that user |
| Passwords | BCrypt cost 12, 12-character minimum, rejected if equal to the email or in a common-password list |
| Enumeration | Unknown address, wrong password and disabled account all return the same `401 INVALID_CREDENTIALS` |
| Abuse | Fixed-window rate limiting: registration 5/hour per IP, login 10 per 5 minutes, refresh and logout 60 per 5 minutes, password change 10/hour |
| Failure shape | One JSON envelope, `{code, message, details, traceId}`, for every endpoint including security failures |

Hashing deserves a note because it is a common examiner question: passwords use a
deliberately slow hash because they are low-entropy and must resist offline guessing;
refresh tokens use SHA-256 because they are 256-bit random values that cannot be
guessed, and because the lookup is by hash, which requires a deterministic function
that a salted password hash could not provide.

### 4.2 Evidence photographs

`POST /api/v1/attachments` accepts one file as `multipart/form-data` from a
signed-in account, thirty times per five minutes. The type is decided by the
content's first bytes, not by the filename or the declared content type: JPEG, PNG
and WebP are accepted, a declared type that contradicts the content is refused with
415, and files over 8 MiB with 413. Stored keys are generated by the server in a
sharded form (`9f/3a/<uuid>.jpg`) and validated against a pattern before any write,
so a key cannot escape the storage directory.

The backend sits behind a `StorageBackend` interface. The filesystem implementation
is adequate for the demonstration; moving to object storage later is one class.

No download endpoint exists, and this is a decision rather than an omission: reading
a photograph must be authorised against the complaint it belongs to, and complaints
do not exist yet. Building the read path first would have meant inventing an
authorisation model that would have to be rewritten.

### 4.3 Deployment tooling

Three scripts and one runbook:

- `infra/deploy/preflight.sh` — refuses placeholder secrets, credentials in the JDBC
  URL, wildcard CORS, a disabled rate limiter, `TRUST_FORWARDED_FOR` without a
  trusted proxy, and a missing storage directory. It never prints a secret.
- `infra/deploy/db-check.sh` — connects with `psql` using the same CA certificate
  and `sslmode=verify-full` as the API, then verifies the tables and columns the code
  queries. Read-only. `--cleanup` removes the accounts left by the smoke test.
- `infra/smoke/auth-smoke.sh` — 35 executable checks of the identity contract,
  including token rotation and replay-triggered revocation. Run in CI.
- `infra/deploy/backup-drill.sh` — dumps the database, restores it into a throwaway
  container, and compares row counts table by table.

## 5. Verification and evidence

| Level | What it proves | Status |
|---|---|---|
| Unit tests (14 classes, 53 tests) | Password policy, token claims, rotation logic, rate limiter, upload policy, path safety | Compiled and green on 2 November 2026 (`mvn test`, developer machine) |
| Integration test (`AuthFlowIT`, Testcontainers) | Register → login → rotate → replay → logout against a real PostgreSQL with TLS | **Not yet run** |
| Container build | The image builds and its unit tests pass | **Not yet run** |
| Smoke test (35 checks) | The wire contract of the identity endpoints | **Not yet run** against the merged code |
| Database check | Hosted database reachable with verified TLS and the expected schema | Script written; **not yet run** |
| Schema equivalence | Hosted schema versus `V1__init.sql` | Verified 4 November 2026 from the dashboard schema listing: same 13 tables and 107 columns |

The distinction between "written" and "verified" is the point of this section. Three
of the rows are outstanding at the date of writing, and the report says so.

## 6. Use of AI assistance

The code in this track was written with an AI coding agent working from the project
bible and the repository, under the university's disclosure requirements. What was
produced and what was checked are recorded chronologically in `AI_USAGE.md`; that
file, not this chapter, is the authoritative record.

Two points are worth stating explicitly:

1. **The agent had no Java toolchain.** It could not compile, run tests, or start a
   container. Every claim of "works" in the code comments is therefore a design
   claim, and verification came from the developer's machine and from CI.
2. **Verification is human-owned.** The first real compile found a genuine defect —
   a test asserting a URL where the implementation produced a bare string — and a
   live run found an authorisation bug: logout had been placed behind the access
   token rule, so a user whose token had expired could never end their session. Both
   were fixed as a result of human-run tests, which is precisely the review loop the
   disclosure is meant to make visible.

## 7. Limitations

Stated here rather than left to be discovered:

1. No deployment exists yet, so G1 is unmet and the G2–G4 criteria that require a
   public URL are at risk.
2. No email transport, so there is no address verification, no password reset, and
   login is not gated on `email_verified`.
3. Registration reveals whether an address is already registered.
4. Staff, supervisor and administrator accounts must be inserted by hand.
5. The rate limiter is per process; it would need a shared store for more than one
   instance.
6. Uploads are stored but not yet linked to a complaint, and there is no download
   endpoint.
7. The hosted database has no migration history and was created by applying
   `V1__init.sql` by hand. Whether to baseline it or recreate it is an open decision,
   and until it is taken no forward migration can be applied safely.
8. The free tier provides no automatic backups, so the manual dump is the backup.

## 8. Reflection

The most transferable lesson from this track is that security controls have a cost
in developer friction, and if that friction is not designed for, people work around
it. Requiring `verify-full` and disabling automatic migrations made the hosted
database the only place the API would start — which is why ADR-003 exists at all.
The second lesson is about evidence: a test suite that has never been run is a
hypothesis, and the report is more credible when it separates what was proven from
what was merely written.
