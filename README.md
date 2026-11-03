# Fix Loop

A campus complaint and resolution tracker, based on the supplied
[project bible](docs/bible/Fix_Loop_Project_Bible_v0.2.md). This is an early
foundation and **must not be used for real reports or real users yet**.

## What exists today

- A Flutter 3.41.9 / Dart 3.11.5 **design preview** based on the supplied
  [Stitch design](docs/design/stitch-design.md): campus home, the four-step
  report flow, report confirmation, resolved-issue detail, loop-closed screen,
  and feedback. The design's light/dark colors, fonts and moon motif are shared.
- Preview navigation, search, form validation, example issue actions and local
  image selection. Examples and draft state are in memory; **nothing is sent to
  the API**. Selected images may be cached temporarily by the operating system
  or image-picker plugin. Use only synthetic information and images.
- A Java 21 / Spring Boot 3 API with health checks, Swagger UI, deny-by-default
  security, and a server-side PostgreSQL JDBC configuration for Supabase.
- Tests and CI using **disposable** PostgreSQL databases. The default Compose
  file no longer creates a local PostgreSQL service.

**Not implemented:** registration, login, JWTs, real complaint or feedback
endpoints, routing, workflow authorization, image uploads, notifications, a
Flutter API client, or a public deployment. A success screen is a preview, not
proof of a submission. The API's domain routes remain denied until real
server-side authentication and authorization exist. Flutter never receives a
database password or Supabase service-role key.

## Important: exposed database credential

An apparent Supabase database password was present in a tracked configuration
file. Although the file has been removed from the current tree, the password
**remains in Git history**. Treat it as compromised: the project owner should
rotate it, review access and update legitimate deployments through a secret
manager. Do not share the replacement in chat or commit it. Removing history
later does not replace rotation.

## Configure the API for Supabase

The app connects through JDBC from **Java to Postgres**, not from Flutter to the
database. No database password or service-role key belongs in the mobile app.

1. In your Supabase project's **Connect** panel, select the **Direct connection**
   and note its host, port, database name and database user. Direct connections
   normally require IPv6 (or Supabase's IPv4 add-on). If your Docker host does
   not have IPv6 connectivity, use the **Session pooler** (port 5432) instead;
   use its host **and its different username** from the dashboard. It still
   reaches Supabase, but through the pooler. Do not use the transaction pooler
   (port 6543) as the default for this long-lived Java pool.
2. Download the project's **server root certificate** from Supabase **Database
   Settings / SSL Configuration**. Save it locally as
   `secrets/supabase-ca.crt`; this CA certificate is public, but the `secrets/`
   directory is ignored by Git. It must be readable by the API container's
   non-root user (on Linux, a public certificate can be `chmod 644`).
3. Copy `.env.example` to `.env` if you don't already have one. Otherwise,
   edit your existing ignored `.env` without overwriting other local settings.
   Set these values locally, using the dashboard's details:

   ```dotenv
   # Format only; substitute your own host and database. Do not include ?query parameters.
   DATABASE_URL=jdbc:postgresql://db.YOUR_PROJECT_REF.supabase.co:5432/postgres
   DATABASE_USER=postgres
   DATABASE_PASSWORD='your-database-password'
   DATABASE_POOL_SIZE=4
   SUPABASE_CA_CERT_PATH=./secrets/supabase-ca.crt
   ```

   With a session pooler, replace both the host and user with the values from
   its Connect panel. Keep password separate from the URL; for `.env`, use
   single quotes if it contains `$` or `#`, and escape a literal single quote
   as `\'` according to Compose's `.env` syntax. Never commit or post the
   password. `DATABASE_URL` deliberately rejects embedded credentials and all
   query parameters so they cannot override the app's TLS settings.
4. With Docker Engine/Desktop and Compose v2 installed, run from the repo root:

   ```sh
   docker compose up --build -d
   docker compose ps
   docker compose logs -f api
   ```

   Ctrl+C stops viewing logs, not the API. The public root CA is mounted
   read-only at `/run/secrets/supabase-ca.crt`. The PostgreSQL driver uses
   `sslmode=verify-full`: it validates the CA **and the hostname**, failing
   closed if either is wrong. The container keeps a small connection pool.
5. Check the API on your computer:

   - <http://localhost:8080/api/v1/health> — API process liveness.
   - <http://localhost:8080/actuator/health> — includes a database readiness
     check; `UP` means this running API can reach its configured database.
   - <http://localhost:8080/swagger-ui/index.html> and
     <http://localhost:8080/v3/api-docs> — generated API documentation.

   Change the port in these URLs if you set `API_PORT`. No domain endpoints are
   open. The API binds to localhost by default; exposing it to a LAN or the
   internet is inappropriate until auth, HTTPS and CORS are reviewed.

For a Java process **outside Docker**, set `DATABASE_URL`, `DATABASE_USER`,
`DATABASE_PASSWORD` and `DATABASE_SSL_ROOT_CERT` (the absolute path to the
same downloaded CA file) as environment variables, then run the API with Java
21 and Maven. The Compose-only `SUPABASE_CA_CERT_PATH` is a host mount path;
it is not the JDBC driver's in-container path.

If startup fails, check: the CA file exists and is readable, the URL has no
query parameters, the username matches the chosen direct/pooler endpoint,
the password is current, and the network supports the selected endpoint's
IPv6/IPv4 requirements. Don't disable certificate or hostname verification to
work around an error. A successful connector inspection is not a JDBC test;
the first real JDBC verification must be performed in your configured environment.

### Existing local data

The former Compose `db` service and `postgres_data` declaration have been
removed from the configuration. **No existing Docker volume is deleted by this
change.** An old database container may remain as an orphan when you start the
new configuration; assess it before stopping or removing it. Do not run
`docker compose down --volumes`, volume-prune commands, or other cleanup that
could permanently delete data unless you have reviewed backups and explicitly
intend to delete it. Local and Supabase databases are separate; changing the
connection does not transfer or synchronize their contents.

### Database migrations and security review

The original `V1__init.sql` remains unchanged. Automatic Flyway migrations are
**disabled** and the API fails startup if they are enabled under its normal
profile. Its integration tests opt in only for a newly created disposable test
container. The read-only Supabase inspection found application tables but no
visible `flyway_schema_history`; Supabase's migration history is separate.
Never run V1, baseline, seed, or otherwise modify the hosted schema until the
team reviews schema equivalence, backups, migration ownership and an explicit
forward-only plan. `infra/seed/seed.sql` is for disposable synthetic databases
only, never Supabase.

The same inspection found three public analytics views with anonymous SELECT
and owner-run behavior, which **may** expose aggregate information via the
public REST schema; external REST access was not tested. Review access with the
project owner before using real data. The existing schema also lacks some bible
privacy fields/events, and the API does not yet implement the required privacy
and authorization guarantees.

Official references: [Supabase connection methods](https://supabase.com/docs/guides/database/connecting-to-postgres),
[Supabase SSL](https://supabase.com/docs/guides/platform/ssl-enforcement), and
[pgJDBC TLS verification](https://jdbc.postgresql.org/documentation/ssl/).

### Optional local tools

MinIO and Mailpit remain optional, disconnected development tools. Configure
unique local-only credentials in `.env` and use:

```sh
docker compose -f docker-compose.yml -f infra/compose-tools.yml up -d
```

MinIO's console defaults to <http://localhost:9001> and Mailpit to
<http://localhost:8025>. Their volumes also persist unless explicitly deleted.

## Flutter on your computer

See [apps/mobile/README.md](apps/mobile/README.md) for setup and preview
instructions. The standard Android and web host projects are generated locally
and are not committed yet. Review their application ID and generated source
before committing them; never commit local properties, signing keys or secrets.

## Testing

- `mvn -f apps/api/pom.xml verify` with Java 21, Maven and Docker runs unit
  tests plus Flyway/security tests on a new disposable PostgreSQL 16 container.
- In `apps/mobile`, run `flutter analyze` and `flutter test` using Flutter
  3.41.9. CI also builds web and an Android debug APK.
- CI builds the API container, runs it against a separate TLS-enabled disposable
  PostgreSQL container, checks the JDBC connection is encrypted and confirms
  no Flyway history was created on startup. It never connects to Supabase.

## Project layout

```text
apps/api/             Spring Boot API, tests and Dockerfile
apps/mobile/          Flutter preview, offline fonts and widget tests
docs/design/          Supplied Stitch design system
docs/bible/           Supplied project bible (v0.2)
docs/openapi/         Small contract for the endpoints that exist today
infra/seed/           Synthetic data for disposable tests only
infra/compose-tools.yml  Optional MinIO and Mailpit
```

Keep secrets and real student data out of the repository. See
[AI_USAGE.md](AI_USAGE.md) for the required AI-assistance log.
