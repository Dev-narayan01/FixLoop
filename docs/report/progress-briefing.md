# Track C — platform and quality: where it stands

One page. Read the script out loud, then show the three screens listed at the bottom.

## 1. What Track C owns

The other two tracks build features: complaints and routing (Dushyant), the mobile app (Yash).
Track C is what lets those features be **deployed, trusted and demonstrated**. Concretely:

- the runnable API shell — configuration, health, error handling, OpenAPI contract;
- the security layer — identity, sessions, upload safety, rate limits;
- the quality evidence — automated tests and a written record of what is and is not verified;
- the operational path — how the system reaches a real database and how it recovers from one.

Three decisions are recorded as ADRs so the reasoning survives after the marks are given:
modular monolith over microservices, Spring Boot over the alternatives, and a local database
next to the hosted one with the hosted one as the reference.

## 2. What is built and proven

**Identity (D7) — complete.** Register, log in, `/me`, rotating refresh tokens, logout, and a
JSON 401 instead of a default HTML error page. Passwords are hashed with BCrypt and screened
by a policy test. Seven rate limits are enforced per route: registration 5 per hour, login 10
per 5 minutes, refresh 60 per 5 minutes, logout 60 per 5 minutes, password change 10 per hour,
photo upload 30 per 5 minutes, notification reads 120 per 5 minutes.

**Attachments — complete.** Complaint photographs are accepted only as JPEG/PNG, under the
size cap, with the file type checked by content and not by name, stored under a generated
name, and recorded with a SHA-256 checksum. A failed disk write produces a clean error
instead of a stack trace.

**Notifications (G3) — complete.** The database already had an outbox table, so the inbox is
built on it rather than beside it: every read is scoped to the signed-in user, reads are
idempotent, and a foreign notification is a 404 rather than a 403 so it does not confirm that
someone else's record exists.

**Automated tests — 57 unit tests, all green.** Thirteen test classes covering identity,
attachments, notifications, the rate limiter, the health endpoint, and the configuration
guards. The build compiles and produces a runnable jar.

**Deployment tooling.** A preflight check, a database check with 27 assertions (configuration,
TLS, schema, safety), a backup-and-restore drill, and a runbook written so that someone who
has never seen the project can bring it up.

## 3. What is not proven yet — say this plainly

- **Integration tests do not run on my machine.** Two integration test classes are written
  (ten methods). They need Docker, and Docker is not installed in the WSL environment I build
  in. The failure is `Could not find a valid Docker environment` — an environment fault, not a
  code fault, and it is recorded as such rather than reported as a pass.
- **The hosted database check has not gone green.** It stopped at a placeholder in the local
  `.env` file; the script has since been fixed to name the offending line, and the entry has
  to be filled with the real project host before the check can run.
- **Nothing raises a notification yet.** The inbox is built and tested; wiring it into the
  complaint workflow is a separate, small change.
- **Synthetic data (G4) has not started.** The generator file exists and is empty. Due 20 Nov.

## 4. The next four things

1. Fill the database entry, run the check, expect 0 failures.
2. Turn on Docker's WSL integration, run the two integration classes.
3. Run the backup-and-restore drill once and record the output.
4. Write the synthetic-data generator for the routing evaluation, then wire notifications in.

## 5. Screens to show, in this order

1. **Terminal:** `mvn -B -ntp -f apps/api/pom.xml test | tail -5` — ends in
   `Tests run: 57, Failures: 0, Errors: 0` and `BUILD SUCCESS`.
2. **`docs/quality/security-checklist.md`** — the checklist with its four honest states:
   done, open, unverified, not applicable. Point at the "unverified" rows; that is the point.
3. **`docs/openapi/openapi.yaml`** — twelve endpoints on one contract, which is what the mobile
   track codes against.

If asked "what would you do with more time": make the unverified rows verified, starting with
the integration tests, because an unrun test is a claim, not evidence.
