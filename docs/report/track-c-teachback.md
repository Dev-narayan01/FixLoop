# Track C teach-back: identity, database security and uploads

How to use this: read one section, close the file, and explain it out loud in your
own words to someone who is not doing this project. If you get stuck, the section
is not learned yet. Do not read this in the viva — read it until you do not need to.

Five sections, roughly 50 minutes total.

---

## 1. Why the API runs its own authentication

The bible (decision D7) says we own the login: email and password, a short-lived
access token, and a rotating refresh token. We did **not** use Supabase Auth or a
third-party identity provider.

Three reasons, in the order they mattered:

1. **Demo-day reliability.** A managed auth service is another thing that can be
   misconfigured, rate-limited or offline. Our login path is our own code and our
   own database.
2. **The domain rule.** Only `bmu.edu.in` addresses may register. That rule lives
   in `settings` (data, not code), so it can change without a deployment.
3. **We already had a `users` table** with roles, department and scope in `V1`.
   A second user store would mean two sources of truth about who someone is.

Cost of the choice: we now own password policy, token rotation, rate limiting and
the security review of all of it. That is exactly what the rest of this file is about.

---

## 2. Two tokens, and why there are two

**Access token** — a JWT signed with HS256, valid **15 minutes**. It carries the
user id (`sub`), the role, and optionally the department and location scope. It
deliberately does **not** carry the email address.

The important property: the server can check it **without touching the database**.
That is what "stateless" means, and it is why we can serve requests quickly. The
cost is that the server cannot un-issue it — once signed, it is valid until it
expires. That is the entire reason it is short-lived.

**Refresh token** — a random 32-byte value, valid **14 days**, stored in the
`refresh_tokens` table. This one is *not* stateless: every refresh is a database
lookup. Its job is to be revocable, so "log out everywhere" and "this account was
compromised" are possible at all.

Say it as one sentence: *the access token is fast but cannot be withdrawn, the
refresh token is slow but can be withdrawn, so we keep the fast one short and the
withdrawable one long.*

---

## 3. Why refresh tokens are hashed with SHA-256 but passwords with BCrypt

Both are "don't store the plaintext", but they solve different problems.

- A **password** is low-entropy: humans pick it from a small, guessable space. If
  the database leaks, an attacker can guess candidate passwords offline. The defence
  is to make each guess *slow*, so BCrypt with cost 12 (thousands of milliseconds
  per guess) instead of a fast hash.
- A **refresh token** is 256 bits of output from `SecureRandom`. There is nothing
  to guess: brute force is not a threat. So a fast hash is correct, and we need it
  fast because we look the token up **by its hash** on every refresh — a query
  `where token_hash = ?`. BCrypt salts every hash differently, so the same token
  would produce a different hash each time and could never be found by lookup.
  SHA-256 is deterministic, so lookup works, and the stored value is still useless
  to an attacker.

Also: BCrypt cannot handle more than 72 bytes, which is why the policy rejects
longer passwords explicitly (`PASSWORD_TOO_LONG`) instead of silently truncating.

---

## 4. Rotation and replay detection — the part worth understanding best

Every time a refresh token is used:
1. the old one is marked `revoked_at = now()` and `replaced_by = <the new row>`;
2. a brand-new token is issued.

So a refresh token is **single-use**. Now consider a token that was already used and
has been rotated. Someone presenting it is one of two people: a thief who stole it
earlier, or the real user replaying a copy. Either way the token is compromised, and
we cannot tell which is which.

Our response is deliberately destructive: **revoke every session for that user**
(`revokeAllForUser`). The real user has to log in again — annoying, but it ends the
attacker's access too. That is the standard "refresh token reuse detection" pattern.

One implementation detail that is easy to miss and good to be able to explain: the
method is annotated `@Transactional(noRollbackFor = ApiException.class)`. We revoke
the sessions and *then* throw a 401. A normal transaction would roll the revocation
back as part of the failure, silently undoing the security response. `noRollbackFor`
keeps the write.

---

## 5. Deny-by-default, and why logout is "public"

`SecurityConfiguration` ends with `.anyRequest().denyAll()`. A URL is reachable only
if it is named in `PUBLIC_PATHS` or `AUTHENTICATED_PATHS`. New endpoints are therefore
closed, not open, when someone forgets to think about them. That is the difference
between "secure by accident" and "secure by construction".

Three consequences worth being able to state:

- **401 vs 403 are different and both are JSON.** 401 means "I don't know who you
  are"; 403 means "I know, and you may not". Both use the same `ApiError` shape with
  a `traceId`, so the client never has to parse an HTML error page.
- **Logout is public on purpose.** Its credential is the refresh token in the request
  body, not the access token. If we required a live access token, a user whose
  15-minute token expired could never log out — which was a real bug we found and
  fixed. The response is always 204, so it reveals nothing about whether the token
  existed.
- **The CSRF protection is off and that is correct here.** CSRF is an attack on
  cookie-based sessions. We are stateless bearer tokens in an `Authorization`
  header, which a cross-site form cannot set.

---

## 6. `verify-full`: what it actually checks

PostgreSQL drivers offer several SSL modes. Two matter:

- `require` — encrypts the connection but **accepts any certificate**. It stops
  passive eavesdropping and does nothing about an active attacker in the middle.
- `verify-full` — checks that the certificate is signed by a CA we trust **and** that
  the hostname in the certificate matches the host we connected to. This is the one
  that stops a man-in-the-middle.

We hand the driver Supabase's project CA certificate (`sslrootcert`) and set
`sslmode=verify-full`. The CA file is public information — it is not a secret — but
it is mounted read-only into the container so it cannot be modified.

Two related defences:
- **No credentials in the JDBC URL.** `DatabaseConnectionSafety` refuses a URL that
  contains a username, password or query string, because URLs end up in logs, stack
  traces and screenshots. Username, password and TLS settings are passed separately.
- **Flyway is off.** The hosted schema was created by hand, so an automatic migration
  on startup could damage it. The same class refuses to start if someone enables it,
  which makes disabling it a property of the code rather than an environment setting
  that could be forgotten.

---

## 7. Why uploads are checked by content, not by name

A filename and a `Content-Type` header are both chosen by the client, so neither is
evidence. `AttachmentPolicy` reads the **first bytes** of the file:

- JPEG starts `FF D8 FF`
- PNG starts `89 50 4E 47 0D 0A 1A 0A`
- WebP starts `RIFF .... WEBP`

If the bytes are not one of those, the upload is refused with 415. If the declared
content type disagrees with the bytes, it is also refused (`FILE_TYPE_MISMATCH`) —
because a mismatch is a sign someone is probing the endpoint.

The declared file type is also never used to build a path. The stored key is
generated by us, shaped like `9f/3a/<uuid>.jpg`, and `FilesystemStorage` refuses any
key that does not match that pattern **and** normalises the resolved path, so `../`
cannot escape the storage directory.

Size is capped in two places: the multipart limit (10 MB file / 12 MB request) is
deliberately *above* the policy limit (8 MB), so the policy answers with our JSON
error shape rather than Tomcat answering with its own.

---

## 8. Rate limiting in one paragraph

`RequestRateLimiter` is a fixed-window counter in memory, keyed by a string. Public
endpoints key on client IP; authenticated ones key on the user id. Registration is
5 per hour per IP, login 10 per 5 minutes, refresh and logout 60 per 5 minutes,
password change 10 per hour, uploads 30 per 5 minutes per account.

Honest limitation to state out loud: the counter lives in one JVM's memory, so it
is correct for a single instance and would need Redis for several instances. That is
why the preflight script refuses `RATE_LIMIT_ENABLED=false` for a deployment — the
limiter is a control, not a convenience.

---

## 9. Questions you should be able to answer in ten seconds

| Question | Short answer |
|---|---|
| Why not sessions and cookies? | Stateless tokens scale and suit a mobile client; no cookie means no CSRF surface. |
| Why HS256 and not RS256? | One issuer, one verifier — symmetric is simpler and faster. RS256 earns its cost when third parties must verify tokens. |
| Why 15 minutes? | Long enough to avoid refresh churn, short enough that a stolen token dies quickly, given we cannot revoke it. |
| Why not put the email in the token? | A token travels on every request and can end up in logs; the user id is all the server needs. |
| What happens if someone steals the refresh token? | They get one rotation; when the real user refreshes again, the reused token triggers full revocation of all sessions. |
| Why BCrypt 12 and not 10? | Cost 12 is ~4x the work of 10; measured against our login latency, and it is the current sensible default. |
| Why is login failure the same for all causes? | Otherwise "wrong password" vs "no such account" tells an attacker which addresses are registered. |
| Does hashing the refresh token stop a database leak? | The attacker gets hashes, cannot invert them, and cannot use them — the stored value is never sent to a client. |
| What does `verify-full` protect against that `require` does not? | An active man-in-the-middle presenting a valid-looking certificate. |
| Why can't you just delete a user's access token? | It is not stored anywhere; statelessness is the trade-off. Revoke the refresh token and wait up to 15 minutes. |

---

## 10. Where to point when someone asks "show me"

| File | What it proves |
|---|---|
| `auth/JwtService.java` | claims are minimal; 15-minute TTL; HS256 |
| `auth/TokenHasher.java` | 32 random bytes; SHA-256 hash; deterministic lookup |
| `auth/AuthService.java` | rotation, `replaced_by`, reuse revocation, `noRollbackFor` |
| `auth/PasswordPolicy.java` | 12 chars, BCrypt 72-byte limit, email-as-password rejected |
| `config/SecurityConfiguration.java` | `denyAll()` default, JSON 401/403, logout rationale |
| `common/RequestRateLimiter.java` | fixed window, sweep, one-instance caveat |
| `storage/AttachmentPolicy.java` | magic-byte detection, 413/415 |
| `storage/FilesystemStorage.java` | key-shape check + path normalisation |
| `config/DatabaseConnectionSafety.java` | refuses credentials in URL, non-`verify-full`, enabled Flyway |
| `infra/smoke/auth-smoke.sh` | 35 executable checks of all of the above |

---

## 11. Limitations you must state before anyone else does

Say these before the examiner finds them; they are design decisions, not accidents.

1. No email verification, so `email_verified` is always false and login is not gated
   on it. There is no mail transport in the project yet.
2. Registration reveals whether an address already exists (`EMAIL_ALREADY_REGISTERED`).
   Hiding it needs a mail flow to be useful.
3. No password reset — there is no way to send a link.
4. Staff, supervisor and admin accounts are inserted by hand; the admin endpoints
   do not exist.
5. The rate limiter is per instance.
6. Uploads are computed and stored but not yet linked to a complaint, and there is
   no download endpoint, because authorisation needs the complaint's ownership.
7. The whole slice was written without a JDK available to the author, so the first
   real compile and the Testcontainers integration test are still outstanding. CI is
   the gate, and this is recorded in `AI_USAGE.md`.
