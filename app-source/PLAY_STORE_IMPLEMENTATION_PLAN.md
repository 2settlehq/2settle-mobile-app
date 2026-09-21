# 2Settle Play Store readiness — implementation plan

Companion to `PLAY_STORE_READINESS_AUDIT.md` (Sept 15, 2026 re-audit). Each audit finding is a standalone task with an owner (which codebase it's actually fixed in) and acceptance criteria. Task IDs reference the audit's finding numbers (`#N`) for traceability.

**Status updated Sept 21, 2026** against actual commit history (`git log`), not assumptions — several tasks were completed directly by the repo owner (commits `3f3a7d4`, `e0fb9cd`, `ac4e928`, `0a85133`, `9bc5026`, Sept 15–18) in parallel with/after the initial planning pass. Legend: ✅ done and verified in current code · ⏳ not started · 🚫 blocked (see notes).

**Three separate codebases are in play — do not conflate them:**
- **`app-source`** (this repo) — the Flutter app. Directly implementable here.
- **`mobile-api`** (sibling repo, `C:\Users\hp\Projects\Sirfi\2settle-mobile-app\mobile-api`) — the Vercel gateway that holds the HMAC signing secret. Directly implementable, but is a separate checkout/deploy from this app.
- **`payment-engine` (external backend)** — the real payment/ledger/auth system that `mobile-api` proxies to. **Not present in any checkout available here.** Tasks that require backend-side changes are listed in Section C as handoff tickets.

---

## A. `app-source` (Flutter app)

| Task | Status | Audit ref | Title | Notes |
|---|---|---|---|---|
| A1 | ✅ | #3, #29 | Wire real sign-out | Both Settings and Dashboard sign-out now call `AuthService.logout()` and `context.goNamed(...)`. |
| A2 | ✅ | #4 | Make `clearSession()` clear everything | Clears tokens/profile/login-identifier. **Deliberately keeps the local PIN** (commit `e0fb9cd`) — reasoned decision: the PIN gates the device, not the account, so sign-out shouldn't force PIN recreation. Safe because PIN-only unlock with no valid token now forces full re-login (A4). |
| A3 | ✅ | #5 | Secure PIN storage + retry lockout | `PinService` — salted PBKDF2-SHA256 hash in `flutter_secure_storage`, escalating lockout after 5 failed attempts. |
| A4 | ✅ | #6 | PIN unlock re-validates session server-side | `AuthService.validateSession()` called after local PIN match; invalid/expired session forces re-login instead of Dashboard. |
| A5 | ✅ | #7 | Real route guards | `requireAuth: true` on all 33 authenticated routes; `AppStateNotifier.loggedIn` now reflects real app-session state, not the unused Firebase stream. |
| A6 | ✅ | #8 | Implement token-refresh flow | `AuthService.refreshAccessToken()` + `validateSession()` refreshes transparently, force-clears session on definitive rejection. |
| A7 | 🚫 | #9 | In-app "Delete account" flow | Still blocked on **C1** — no backend deletion endpoint exists to call. |
| A8 | ✅ | #10, reconciled finding | Fix missing Authorization headers on gift create/cancel/bank-validate | Fixed in commit `e0fb9cd` — all three now send `Bearer ${AuthService.getAccessToken()}`. The original "may be broken in prod" concern (D1) is resolved by this. |
| A9 | ✅ | #17 | Move tokens to secure storage | Access/refresh tokens in `flutter_secure_storage`. |
| A10 | ✅ | #18 | Splash validates session, not just PIN presence | Splash still only checks PIN presence by design — the actual session check happens one screen later at PIN-unlock (A4), so it isn't duplicated. |
| A11 | ⏳ | #19 | Fix or remove dead-end Settings rows (Currency Options, Support, Invite Friends) | Not started. |
| A12 | ⏳ | #20 | Finish or remove KYC / Tier level entries | Not started. |
| A13 | ⏳ | #21 | Finish or remove account-linking stubs (Phone/Wallet/Email/Google) | Not started. |
| A14 | ⏳ | #22 | Reconcile version strings; read real build version | Splash still hardcodes `'2Settle V2.36.38'` (`splash_screen_widget.dart:29`) against `pubspec.yaml`'s `1.0.0+1`. Still needs the real live Play Console versionCode confirmed before this is safe to touch. |
| A15 | ⏳ | #23 | Real test coverage (login, session, payment flows) | `test/widget_test.dart` still the unmodified template smoke test. |
| A16 | ⏳ | #1 | Real release signing config | Still signs with `signingConfigs.debug`; `key.properties` still doesn't exist. Needs a human to generate an upload keystore — can't be done from source alone. |
| A17 | ⏳ | #2 | Confirm/lock in release package ID | `.original` suffix still applied to release; still needs confirmation against the live Play Console listing. **Human decision.** |
| A18 | ⏳ | #27 | Re-enable release lint | `checkReleaseBuilds false` still set. Do last — will surface issues from every other change. |
| A19 | ✅ | #28 | Remove vestigial `requestLegacyExternalStorage` | Removed in commit `ac4e928`. |
| A20 | ✅ | #30 | Delete dead `BankNameCheckCall` | Removed in commit `ac4e928` ("removed the call to banks from the mobile app"). |
| A21 | ✅ | #15 (app half) | Route rate/bank calls through `ApiConfig` instead of hardcoded domains | Rate calls done via `0a85133`. Bank-list calls now also centralized: added `ApiConfig.banksListUrl`, updated all 4 call sites (`claim_gift_widget.dart`, `account_details_widget.dart`, `main_transaction_widget.dart`, `receive_account_setup_widget.dart`). Note: this bank-list endpoint is still a direct call to bare `2settle.io` (not proxied through the mobile-api gateway like rate/resolve are) — that upstream's real contract wasn't verified, so only the duplication/inconsistency was fixed, not the routing. |

## B. `mobile-api` gateway

| Task | Status | Audit ref | Title | Notes |
|---|---|---|---|---|
| B1 | ✅ | #11 | Add ownership check to gift claim/confirm | **Reframed, not literally implemented as originally worded.** Gift creation never captures a recipient identity (confirmed: `payer` only, no `receiver` for `type: 'gift'`), so gifts are bearer-style claim codes — nobody "owns" an unclaimed reference the way `callerOwnsReference` checks sender ownership for cancellation. Real equivalent added instead: `claim/confirm.js` now does a pre-flight lookup reusing the same `valid` flag the public gift-lookup route and the app's own claim UI already trust, and rejects (409) a claim attempt against an already-claimed/cancelled/expired reference before forwarding bank details upstream. |
| B2 | ⏳ | #12 | Add rate limiting to public/lightly-authenticated routes | Still open — needs an infra decision (Vercel Edge Config/KV, Upstash) that shouldn't be made silently. This is the task that actually mitigates reference-enumeration risk on the claim/lookup routes. |
| B3 | ✅ | #13 | Redact payment-creation responses (drop `raw`/`upstream`/`request` echo) | Fixed in `api/payments/index.js` — success/error paths now return an explicit field allowlist (verified against every field `create_gift_widget.dart` and `confirm_transaction_widget.dart` actually read: id, reference, type, status, depositAddress, cryptoAmount, crypto, network, fiatAmount, fiatCurrency, rate, charge{fiat,crypto}, transactionUsd, expiresAt, confirmedAt, settledAt). No more `raw`/`upstream`/`request` passthrough. |
| B4 | ✅ | #14 | Strip signing diagnostics from public error responses | Fixed via new `includeDiagnostics()` helper in `lib/signing.js` (env-gated, off by default), applied consistently across all 6 routes that returned `diagnostics` (gifts lookup, cancel, claim/confirm, banks/resolve, payments lookup, payments creation) — not just the one public route, per the audit's "for all routes" note. Also dropped the `upstream: data` passthrough on gift cancellation's error path while there (same class of leak). |
| B5 | ✅ | #15 (gateway half) | Add `GET /api/rates` proxy route | Done in commit `0a85133` as `mobile-api/api/rate.js`, proxying `payment-engine`'s public `/v1/rate`. **Bonus, not originally scoped**: `api/payments/estimate.js` was also added, and `9bc5026` extended payment creation to support a `type: 'transfer'` payout with receiver bank details — new product features beyond the original audit list, not security fixes. |
| B6 | ⏳ | #16 | Idempotency-key handling for payment creation | No idempotency logic found in `mobile-api/api` or `lib` — still open. |
| B7 | ⏳ | #24 | Add a gateway test suite | Still no test script/files. |
| B8 | ⏳ | #25 | Generic config-error messages (stop naming unset env vars) | Not checked this pass — assume still open unless verified. |
| B9 | ⏳ | #26 | Centralize upstream host via env-configurable module | Still hardcoded per-file — not touched. |

## C. External `payment-engine` backend — NOT implementable from here

Unchanged from initial plan — still not present in any checkout available here.

| Task | Audit ref | Title | Unblocks |
|---|---|---|---|
| C1 | #9 | Backend account-deletion endpoint + documented retention policy | A7, Play Console web-deletion-URL requirement |
| C2 | scope limitation | Re-verify OTP hashing, refresh-token rotation, session revocation, HMAC/IP-allowlisting behavior | Confidence in A4/A6 |
| C3 | supports B6 | Confirm whether `payment-engine` already dedupes retried payment submissions server-side | B6 |
| C4 | supports B5 | Confirm `payment-engine`'s `/v1/rate` route is stable in the actual deployed environment | B5 (already live and working per `rate.js`, but re-verify in prod) |
| C5 | supports B1 | Confirm gift-claim recipient identity is enforceable server-side | B1 |

## D. Not code — process/business items

| Item | Status | Audit ref | Action |
|---|---|---|---|
| D1 | ✅ resolved | Reconciled finding | The gift-creation 401 risk is resolved by A8 — the app now sends the Authorization header the gateway requires. No longer an open question. |
| D2 | ⏳ | #2 | Confirm live Play Console package name matches `com.sirfitech.settleio.original`. |
| D3 | ⏳ | #22 | Confirm live Play Console versionCode before any upload. |
| D4 | ⏳ | #31 | Verify `https://spend.2settle.io/privacy` and `/terms` are live with accurate, current policy text. |
| D5 | ⏳ | Play policy section | Complete Data Safety form; complete Financial Features Declaration; confirm EU CASP authorization status if EU is a launch country. |
| D6 | ⏳ | #16 (16KB) | Do an actual signed build + device/emulator check for 16 KB page-size compliance. |

---

## What's actually left, grouped by what it takes

**Can keep doing in code, no blockers:**
- B2, B6, B9 (rate limiting, idempotency, centralized upstream host config)
- A11, A12, A13 (Settings/KYC/Tier/linking — mostly product decisions on finish-vs-remove, then code)
- A15, B7 (test coverage)
- B8 (verify status, likely still open)

**Blocked on a human decision or external action:**
- A16, A17, A18, A14, D2, D3 — all cluster around release signing/versioning; need a real upload keystore generated and the live Play Console listing checked before any of these are safe to touch.
- A7 — blocked on C1 (backend deletion endpoint doesn't exist).
- D4, D5, D6 — need live environment access (hosted pages, Play Console, a real signed build) that isn't available from source alone.

**Done:**
A1, A2, A3, A4, A5, A6, A8, A9, A10, A19, A20, A21, B1, B3, B4, B5, D1 (17 of 21 app/gateway tasks with no external blocker).
