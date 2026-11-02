# AI usage log

| Date (UTC) | Who / tool | Assistance | Human review and follow-up |
|---|---|---|---|
| 2026-10-28 | Arena.ai coding agent, at the repository owner's request | Reviewed the supplied v0.2 project bible and existing repository; drafted the local Docker setup, Spring Boot foundation, security defaults, tests, Flutter placeholder and documentation. Preserved the existing SQL migration; removed the tracked config containing an apparent database credential. | Team review and teach-back are still required. Rotate the exposed credential with the project owner; removing it from the current tree does not remove it from Git history. No Supabase connection was made. |
| 2026-11-01 | Arena.ai coding agent, at Dev Narayan's request | Implemented Track C item 2: student registration, login, rotating refresh tokens, logout, password change and `GET /me`; HS256 access tokens through Spring Security's Nimbus support; BCrypt(12); a per-IP fixed-window rate limiter; the shared error envelope with field details; CORS locked to configured origins; unit and Testcontainers integration tests; OpenAPI, README and `.env.example` updates. | Written without a JDK or Maven available to the agent, so it had never been compiled. Trade-offs recorded deliberately: registration reveals whether an address already has an account; login is not gated on `email_verified` because no mail is sent yet; `JWT_SECRET` is optional locally but the API logs a warning and uses an ephemeral key when it is missing; the rate limiter covers one instance only; staff and supervisor accounts still need to be inserted by hand. |
| 2026-11-02 | Dev Narayan, running the first real check | `mvn -B -f apps/api/pom.xml test` in WSL: compilation succeeded, all 20 unit tests executed, 19 passed. | The one error was in the agent's own test, not the application: `Jwt.getIssuer()` parses the `iss` claim as a URL and the default issuer was the bare word `fixloop`. Fixed by making the default issuer the URI `https://fixloop.local` (override with `JWT_ISSUER`) and by reading the raw `iss` claim in the test. Re-run `mvn test` to confirm 20 of 20, then run the smoke test against a live API. |

Automated verification: the original migration and sample seed were checked on a
disposable PostgreSQL 16 instance, and the initial GitHub Actions run passed the
Java, Docker and Flutter checks.

Verification status of the authentication work: **compiled and unit tested by
Dev Narayan on 2026-11-02** (one test-only bug fixed afterwards, re-run
pending). The Testcontainers integration test (`AuthFlowIT`) and the container
build have **not** been run yet, because Docker is not enabled in his WSL
distribution; CI is the next real check.

Do not merge AI-generated changes unread. Record subsequent human changes and
verification here in accordance with the project bible.
