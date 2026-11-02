# Fix Loop

A campus complaint and resolution tracking system. This repository is an early
**foundation**, based on the supplied [project bible](docs/bible/Fix_Loop_Project_Bible_v0.2.md).
It is not yet a working complaint system and must not be used with real users
or real complaints.

## What exists today

- Java 21 / Spring Boot 3 API, public health checks, Swagger UI and a
  deny-by-default security configuration.
- **Student registration, login, rotating refresh tokens, logout, password
  change and `GET /me`**, with BCrypt password hashing, short-lived HS256 access
  tokens, per-IP rate limiting and role claims. See
  [Authentication](#authentication-implemented).
- Local PostgreSQL 16 and API containers. Flyway applies the existing `V1`
  migration to a **fresh local database**; the original SQL has not been edited.
- Optional local MinIO and Mailpit containers for future storage/email work,
  plus a small, explicitly synthetic reference-data seed.
- A Flutter 3.41.9 / Dart 3.11.5 login **placeholder** for Android and web.
  Its controls are disabled; no credentials are collected.
- Tests and GitHub Actions configuration for the API, database and Flutter shell.

**Not implemented:** email verification, admin-created staff accounts,
complaint endpoints, routing, workflow, ownership checks on complaints
(there are no complaints yet), uploads, notifications, a real API client, or a
public deployment. The existing tables alone do not enforce all
those rules. The starter is not production-ready.

## Important: exposed database credential

An apparent Supabase database password was present in a tracked configuration
file. The file has been removed from the current working tree, but the password
**remains in Git history**. Treat it as compromised: someone with access to the
Supabase project should rotate the database password immediately, review access,
and update any legitimate deployments through their secret manager. Do not
share the new credential in chat or commit it. Removing history later does not
replace rotation. No Supabase connection is needed for this setup.

## Run locally with Docker

Requirements: Docker Desktop (or Docker Engine) with the Compose v2 plugin,
Git, and an internet connection for the first image build. Java and Maven do
**not** need to be installed locally to start the API. If Docker is not yet
installed, install and start Docker Desktop/Engine first, then check
`docker --version` and `docker compose version`.

From the repository root:

1. Copy `.env.example` to `.env` (`cp .env.example .env` on macOS/Linux;
   `Copy-Item .env.example .env` in PowerShell).
2. Edit `.env` locally and set **`POSTGRES_PASSWORD`** to a new, non-empty,
   local-only password. For example, `openssl rand -hex 24` generates one on
   systems with OpenSSL. Keep the password private and do not reuse a Supabase
   credential. The blank database/user values default to `fixloop`; port
   settings can stay blank. `.env` is ignored by Git.
3. Start the stack:

   ```sh
   docker compose up --build -d
   docker compose ps
   ```

   The first build downloads dependencies, runs the Java unit tests, waits for
   PostgreSQL to become healthy, and applies the migration. Check progress with
   `docker compose logs -f api` (Ctrl+C stops viewing logs, not the stack).
4. Open or query:

   - <http://localhost:8080/api/v1/health> — process liveness only.
   - <http://localhost:8080/actuator/health> — includes the database; returns
     `UP` when ready and a 503 when an essential health check fails.
   - <http://localhost:8080/swagger-ui/index.html> — generated API docs.
   - <http://localhost:8080/v3/api-docs> — generated OpenAPI JSON.

If you set `API_PORT`, use that port instead of 8080. Only health and API docs
are public; all other paths are denied. The database and API bind to localhost
by default. If the team later needs a phone on the LAN to reach the API,
`API_BIND_ADDRESS=0.0.0.0` opts in to exposing it on the host; do this only on a
trusted network and configure authorization and CORS before connecting a real
client. The Flutter placeholder does not call the API yet.

`docker compose down` stops the stack **without deleting database data**. If a
local password is changed after the database was first created, the existing
volume still has the old password: restore the old value or, only for disposable
local data, reset with `docker compose down --volumes`. That command permanently
deletes the local database volume. Do not use it against a system with data you
need.

### Authentication (implemented)

The API issues its own tokens; there is no third-party auth service to fail on
demo day (bible D7).

| Endpoint | Who | Purpose |
|---|---|---|
| `POST /api/v1/auth/register` | Public | Create a STUDENT account on an allowed email domain |
| `POST /api/v1/auth/login` | Public | Exchange email and password for tokens |
| `POST /api/v1/auth/refresh` | Public (with refresh token) | Rotate the refresh token, issue a new access token |
| `POST /api/v1/auth/logout` | Public — the refresh token in the body is the credential | Revoke the presented refresh token, even after the access token expired |
| `POST /api/v1/auth/change-password` | Any signed-in user | Change the password and revoke other sessions |
| `GET /api/v1/me` | Any signed-in user | The caller's account, role and scope |

How it behaves:

- Access tokens live **15 minutes** and carry only the user id, role and scope.
  They never contain the email address.
- Refresh tokens live **14 days**, are stored **only as SHA-256 hashes**, and are
  **rotated on every use**. Presenting a token that was already rotated is
  treated as theft and revokes every session for that user.
- Passwords are BCrypt (strength 12), at least 12 characters, and rejected if
  they are the email address or an obvious default.
- Login failures are indistinguishable: unknown address, wrong password and
  disabled account all return the same `401 INVALID_CREDENTIALS`.
- Login, registration, refresh and logout are rate limited per IP; complaint
  creation will be limited the same way when it exists.
- Every failure uses one error shape with a `traceId`.

Set these in `.env` for local work:

| Variable | Meaning |
|---|---|
| `JWT_SECRET` | Signs access tokens, at least 32 bytes (`openssl rand -hex 32`). Blank means an ephemeral key that changes on restart. |
| `ALLOWED_EMAIL_DOMAINS` | Comma-separated domains allowed to register students (`bmu.edu.in` by default) |
| `ALLOWED_WEB_ORIGINS` | Comma-separated browser origins for the Flutter web build |
| `TRUST_FORWARDED_FOR` | Only `true` behind a trusted reverse proxy |

Two configuration rows can override this without a deployment: set
`settings.allowed_email_domains` to a comma-separated list, and
`settings.demo_mode_open_signup` to `true` for demo-day open signup (turn it off
afterwards).

**Not done yet:** no confirmation email, so `email_verified` stays `false` and
login is not gated on it; staff, supervisor and admin accounts still have to be
inserted by hand because the admin endpoints do not exist; there is no password
reset. Those are tracked in the bible (FR-105, FR-106, FR-107).

### Test the authentication before you merge

Nothing below needs a GitHub push. Test on a copy of the branch first:

```sh
git fetch origin
git switch -c test-auth origin/arena/53e67ffc-fixloop
```

| Level | What it proves | Needs | Command |
|---|---|---|---|
| 1. Compile + unit tests | The code compiles; password rules, token claims and the rate limiter behave | Java 21 + Maven 3.9 | `mvn -f apps/api/pom.xml test` |
| 2. Container build | The image builds and its unit tests pass | Docker only | `docker compose build api` |
| 3. Integration test | Register, log in, rotate, replay, log out against a **real disposable PostgreSQL 16** | Java, Maven, Docker | `mvn -f apps/api/pom.xml verify` |
| 4. Smoke test | The wire contract: status codes, error codes, token rotation | Docker | `docker compose up -d --wait db api` then `bash infra/smoke/auth-smoke.sh` |
| 5. Manual poke | You want to read the responses yourself | Docker | Swagger UI at <http://localhost:8080/swagger-ui/index.html> |

Notes:

- **Level 1 is the fastest and needs no Docker.** `mvn test` runs the unit
  tests only; the `*IT` classes run during `verify`.
- If Maven is not installed, **level 2 is the honest compile check**: the
  Docker build stage runs `mvn package`, so a compile error fails the build.
- **Level 4** runs 35 checks, prints PASS/FAIL per step and exits non-zero if
  anything failed. It creates one throwaway `smoke-*@bmu.edu.in` account and
  prints the cleanup command (`infra/smoke/cleanup.sql`).
- Registration is limited to 5 per hour per IP, so running the smoke test
  repeatedly can return `429`. Wait, or set `RATE_LIMIT_ENABLED=false` in
  `.env` for the session.
- These tests create data in your **local** database only. Do not run the
  smoke script against a deployment that holds real complaints.

If a level fails, the fix belongs on this branch; `main` has not been touched.

### Optional: synthetic reference data

After the API has started and Flyway has finished, this command inserts a few
**made-up** departments, locations, categories, routing rules and SLA examples:

```sh
docker compose exec -T db sh -c 'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < infra/seed/seed.sql
```

The insert-only script is repeatable on a fresh local database. It creates no
users or complaints and does not implement routing; it is not real campus data.
Do not run it against Supabase or an existing real database.

### Optional: local storage and email tools

Set `MINIO_ROOT_USER` (at least 3 characters) and `MINIO_ROOT_PASSWORD` (at
least 8 characters) in `.env` using unique local-only values, then run:

```sh
docker compose -f docker-compose.yml -f infra/compose-tools.yml up -d
```

MinIO's console is at <http://localhost:9001>; Mailpit's inbox is at
<http://localhost:8025> (SMTP port 1025). These services bind to localhost, are
not connected to the API yet, and are for local development only. To stop the
full stack without deleting its volumes:

```sh
docker compose -f docker-compose.yml -f infra/compose-tools.yml down
```

## Flutter on your computer

Your Flutter **3.41.9 / Dart 3.11.5** is the target version. See
[apps/mobile/README.md](apps/mobile/README.md) for the one-time command that
generates the standard Android and web host projects with your installed SDK,
then runs analysis, tests and the placeholder. The generated host projects are
not committed yet. This screen cannot log in or submit complaints.

## Testing

- `docker compose build api` builds the JAR and runs the Java unit tests.
- With Java 21, Maven 3.9+ and a running Docker daemon installed locally:
  `mvn -f apps/api/pom.xml verify`. This also runs the Testcontainers
  integration tests against a **new disposable PostgreSQL 16 container**; they
  fail rather than silently skipping if Docker is unavailable.
- The identity flows have a Testcontainers integration test
  (`AuthFlowIT`): register, log in, use the token, rotate the refresh token,
  detect replay, change the password and log out. It runs during `mvn verify`
  and in CI.
- `bash infra/smoke/auth-smoke.sh` checks the identity endpoints against a
  running stack and prints PASS/FAIL per step. See
  [Test the authentication before you merge](#test-the-authentication-before-you-merge).
- In `apps/mobile`, after the one-time Flutter setup: `flutter analyze` and
  `flutter test`.
- CI is configured to run these checks, validate Compose, build and smoke-test
  the API container, and build Flutter web.

## Database migration rules

Local note: Compose and CI use PostgreSQL 16. A newer local server (for example
PostgreSQL 18 from a distribution package) also works — Flyway applies the
migration — but logs that it only supports up to 17. That warning is harmless
for local development; do not ignore it if it appears against a hosted database.

`apps/api/src/main/resources/db/migration/V1__init.sql` is the existing schema
and has intentionally been left unchanged. Flyway is configured **not** to
baseline a non-empty database automatically and not to clean databases. Never
edit an applied migration: use a reviewed, forward-only `V2`, `V3`, etc.

The Supabase database's current state and Flyway history are unknown. **Do not
point this starter at it yet**; first inspect the actual schema and migration
history with someone who has access and agree on a safe migration plan. In
particular, V1 does not yet contain the bible's optional `share_identity`
column or `REPORTER_REVEALED` event type. These and other gaps need a reviewed
follow-up migration and authorization tests before those features can work.

## Project layout

```text
apps/api/           Spring Boot application, tests and Dockerfile
apps/mobile/        Flutter source and widget test (host files generated locally)
docs/adr/           Architecture decision records (ADR-001 to ADR-003)
docs/bible/         Supplied project bible (v0.2)
docs/openapi/       Small contract for the endpoints that exist today
infra/seed/         Optional synthetic reference data
infra/compose-tools.yml  Optional MinIO and Mailpit
```

Keep secrets and real student data out of the repository. See
[AI_USAGE.md](AI_USAGE.md) for the required AI-assistance log.
