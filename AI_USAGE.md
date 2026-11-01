# AI usage log

| Date (UTC) | Who / tool | Assistance | Human review and follow-up |
|---|---|---|---|
| 2026-10-28 | Arena.ai coding agent, at the repository owner's request | Reviewed the supplied v0.2 project bible and existing repository; drafted the local Docker setup, Spring Boot foundation, security defaults, tests, Flutter placeholder and documentation. Preserved the existing SQL migration; removed the tracked config containing an apparent database credential. | Team review and teach-back are still required. Rotate the exposed credential with the project owner; removing it from the current tree does not remove it from Git history. No Supabase connection was made. |
| 2026-11-01 | Arena.ai coding agent, at Dev Narayan's request | Implemented Track C item 2: student registration, login, rotating refresh tokens, logout, password change and `GET /me`; HS256 access tokens through Spring Security's Nimbus support; BCrypt(12); a per-IP fixed-window rate limiter; the shared error envelope with field details; CORS locked to configured origins; unit and Testcontainers integration tests; OpenAPI, README and `.env.example` updates. | **Not yet verified by a human.** The working environment had no JDK, Maven, Docker or Maven Central access, so `mvn verify` was never run. Dev must run it, read every file and be able to explain it before merge. Trade-offs recorded deliberately: registration reveals whether an address already has an account; login is not gated on `email_verified` because no mail is sent yet; `JWT_SECRET` is optional locally but the API logs a warning and uses an ephemeral key when it is missing; the rate limiter covers one instance only; staff and supervisor accounts still need to be inserted by hand. |

Automated verification: the original migration and sample seed were checked on a
disposable PostgreSQL 16 instance, and the initial GitHub Actions run passed the
Java, Docker and Flutter checks. The 2026-11-01 authentication work has **not**
been compiled or run yet; treat CI as the first real check and fix forward.

Do not merge AI-generated changes unread. Record subsequent human changes and
verification here in accordance with the project bible.
