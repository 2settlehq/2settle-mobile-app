# 2Settle Play Store readiness — implementation plan

Companion to `PLAY_STORE_READINESS_AUDIT.md` (Sept 15, 2026 re-audit). Each audit finding is broken into a standalone task with an owner (which codebase it's actually fixed in) and acceptance criteria. Task IDs reference the audit's finding numbers (`#N`) for traceability.

**Three separate codebases are in play — do not conflate them:**
- **`app-source`** (this repo) — the Flutter app. Directly implementable here.
- **`mobile-api`** (sibling repo, `C:\Users\hp\Projects\Sirfi\2settle-mobile-app\mobile-api`) — the Vercel gateway that holds the HMAC signing secret. Directly implementable, but is a separate checkout/deploy from this app.
- **`payment-engine` (external backend)** — the real payment/ledger/auth system that `mobile-api` proxies to. **Not present in any checkout available here.** Tasks that require backend-side changes are listed in Section C as handoff tickets, not something that can be implemented from this session. Do not attempt to simulate or stub these — confirm actual behavior with whoever owns that repo before assuming a fix works.

---

## A. `app-source` (Flutter app) — implementable here

| Task | Audit ref | Title | Files | Depends on |
|---|---|---|---|---|
| A1 | #3, #29 | Wire real sign-out | `lib/pages/settings/settings_widget.dart:402-406`, `lib/pages/dashboard/dashboard_widget.dart:1223-1253` | — |
| A2 | #4 | Make `clearSession()` clear everything | `lib/services/auth_service.dart:145-149` | A1 |
| A3 | #5 | Secure PIN storage + retry lockout | `lib/pages/set_app_passcode/set_app_passcode_widget.dart`, `lib/pages/confirm_code/confirm_code_widget.dart`, `pubspec.yaml` (add `flutter_secure_storage`) | — |
| A4 | #6 | PIN unlock re-validates session server-side | `lib/pages/confirm_code/confirm_code_widget.dart:83-101` | A6, A9 |
| A5 | #7 | Real route guards | `lib/flutter_flow/nav/nav.dart:877-909` | A6 |
| A6 | #8 | Implement token-refresh flow | `lib/services/auth_service.dart`, `lib/config/api_config.dart:32` | — |
| A7 | #9 | In-app "Delete account" flow | new page under `lib/pages/`, `lib/pages/settings/settings_widget.dart` | **C1 (backend endpoint must exist first)** |
| A8 | #10, reconciled finding | Fix missing Authorization headers on gift create/cancel/bank-validate | `lib/pages/create_gift/create_gift_widget.dart:245-265`, `lib/pages/gift_claim_details/gift_claim_details_widget.dart:220-225`, `lib/pages/pay_page/pay_page_widget.dart:481-488` | Reproduce against live gateway first (see "Immediate verification" below) |
| A9 | #17 | Move tokens to secure storage | `lib/services/auth_service.dart:19-20,125-131` | Can share `flutter_secure_storage` dep with A3 |
| A10 | #18 | Splash validates session, not just PIN presence | `lib/pages/splash_screen/splash_screen_widget.dart:58-72` | A6 |
| A11 | #19 | Fix or remove dead-end Settings rows (Currency Options, Support, Invite Friends) | `lib/pages/settings/settings_widget.dart:629-641` | Product decision: implement vs. remove |
| A12 | #20 | Finish or remove KYC / Tier level entries | `lib/pages/settings/settings_widget.dart:409-424`, `lib/pages/notifications/notifications_widget.dart:16-25` | Product decision + **C-series if KYC needs backend** |
| A13 | #21 | Finish or remove account-linking stubs (Phone/Wallet/Email/Google) | `lib/pages/security/security_widget.dart:55-116,246-270` | Product decision |
| A14 | #22 | Reconcile version strings; read real build version | `lib/pages/splash_screen/splash_screen_widget.dart:28,181`, `lib/pages/version_history/version_history_widget.dart`, `pubspec.yaml` (add `package_info_plus`) | Needs the real live Play Console versionCode confirmed first |
| A15 | #23 | Real test coverage (login, session, payment flows) | `test/` | Best done after A1-A9 land, so tests aren't written against code about to change |
| A16 | #1 | Real release signing config | `android/app/build.gradle:66-85`, new `android/key.properties` (never commit) | Needs an actual upload keystore generated out-of-band |
| A17 | #2 | Confirm/lock in release package ID | `android/app/build.gradle:76-82` | **Human decision** — confirm against live Play Console listing before touching |
| A18 | #27 | Re-enable release lint | `android/app/build.gradle:52-55` | Do last — will surface issues from every other change |
| A19 | #28 | Remove vestigial `requestLegacyExternalStorage` | `android/app/src/main/AndroidManifest.xml:12` | — |
| A20 | #30 | Delete dead `BankNameCheckCall` | `lib/backend/api_requests/api_calls.dart:11-29` | — |
| A21 | #15 (app half) | Route rate/bank calls through `ApiConfig` instead of 3 hardcoded domains | `convert_widget.dart:29`, `dashboard_widget.dart:34`, `main_transaction_widget.dart:38,41`, `claim_gift_widget.dart:33`, `account_details_widget.dart:66`, `receive_account_setup_widget.dart:44` | B5 (gateway rates route must exist first, for the rate calls specifically) |

## B. `mobile-api` gateway — implementable here (separate checkout/deploy)

| Task | Audit ref | Title | Files |
|---|---|---|---|
| B1 | #11 | Add ownership check to gift claim/confirm | `api/gifts/[reference]/claim/confirm.js:126-153` (mirror `callerOwnsReference` pattern from `cancel/index.js:52`) |
| B2 | #12 | Add rate limiting to public/lightly-authenticated routes | `api/gifts/[reference].js` (GET), `api/gifts/[reference]/claim/confirm.js` |
| B3 | #13 | Redact payment-creation responses (drop `raw`/`upstream`/`request` echo) | `api/payments/index.js:115-137` |
| B4 | #14 | Strip signing diagnostics from public error responses | `api/gifts/[reference].js:16-25,89` and any other route returning `proxyDiagnostics()`/`resolverDiagnostics()` to unauthenticated callers |
| B5 | #15 (gateway half) | Add `GET /api/rates` proxy route | new `api/rates.js` (or similar), proxying `payment-engine`'s `/v1/rate` |
| B6 | #16 | Idempotency-key handling for payment creation | `api/payments/index.js` |
| B7 | #24 | Add a gateway test suite | `package.json` (add `test` script), new test files for `lib/endUser.js` and route-level auth gating |
| B8 | #25 | Generic config-error messages (stop naming unset env vars) | every route currently returning `missing: {TWOSETTLE_API_KEY, TWOSETTLE_SECRET_KEY}` |
| B9 | #26 | Centralize upstream host via env-configurable module | new `lib/config.js`, imported by all ~10 route files currently hardcoding `https://api.2settle.io` |

## C. External `payment-engine` backend — NOT implementable from here

These require someone with access to the actual backend repo. Do not attempt to fix from `app-source` or `mobile-api` — at most, `mobile-api` can be updated to *call* these once they exist (see cross-references).

| Task | Audit ref | Title | What's needed | Unblocks |
|---|---|---|---|---|
| C1 | #9 | Backend account-deletion endpoint + documented retention policy for legally-required financial records | New authenticated deletion endpoint, plus a decision on what data must be retained and for how long | A7, and the Play Console web-deletion-URL requirement |
| C2 | — (scope limitation noted in audit) | Re-verify OTP hashing, refresh-token rotation, session revocation, and HMAC/IP-allowlisting behavior | These were only verified in the Sept 14-15 audit against a `payment-engine` checkout that isn't available now — re-confirm they still hold, don't assume | Confidence in A4/A6's assumption that the backend can actually validate/revoke sessions |
| C3 | supports B6 | Confirm whether `payment-engine` already dedupes retried payment submissions server-side | If it does, B6 may only need to forward a key rather than implement dedup logic in the gateway too | B6 |
| C4 | supports B5 | Confirm `payment-engine`'s `/v1/rate` route is stable and suitable for the gateway to proxy publicly | Already confirmed reachable in the Sept 15 backend re-audit (`http://localhost:3500/v1/rate` returned 200) — re-verify in the actual deployed environment mobile-api will call | B5 |
| C5 | supports B1 | Confirm gift-claim recipient identity is enforceable server-side (does the backend even know/store the intended recipient?) | If the backend has no recipient field to check against, B1 can only be a gateway-side heuristic, not a real fix | B1 |

## D. Not code — process/business items

| Item | Audit ref | Action |
|---|---|---|
| D1 | Reconciled finding | **Reproduce the gift-creation 401 against the real deployed gateway before anything else** — confirm whether production is currently broken |
| D2 | #2 | Confirm live Play Console package name matches `com.sirfitech.settleio.original` |
| D3 | #22 | Confirm live Play Console versionCode before any upload |
| D4 | #31 | Verify `https://spend.2settle.io/privacy` and `/terms` are live with accurate, current policy text |
| D5 | Play policy section | Complete Data Safety form with a fresh data inventory; complete Financial Features Declaration; confirm EU CASP authorization status if EU is a launch country |
| D6 | #16 (16KB) | Do an actual signed build + device/emulator check for 16 KB page-size compliance — config inspection alone doesn't prove it |

---

## Suggested implementation order

1. **D1** — reproduce the gift-creation break first; it may already be live-broken, which outranks everything else.
2. **A1 → A2 → A9 → A3 → A6 → A4 → A5 → A10** — the whole auth/session chain, in this order, since each later step assumes the earlier one exists (can't validate sessions server-side before refresh exists; can't gate routes before there's a real logged-in signal).
3. **A8**, informed by D1's finding.
4. **B1 → B3 → B4 → B2 → B6** — gateway hardening, independent of the app-side chain, can happen in parallel with step 2.
5. **C1**, in parallel — hand off now since it blocks A7 and has the longest lead time (needs a backend-owner decision on retention policy).
6. **A16 → A17 → D2 → D3 → A14** — signing/versioning, once the package-ID/versionCode questions are answered by a human.
7. Everything else (A11-A13, A18-A21, B5/B7-B9, D4-D6) — lower risk, can be parallelized or done last.

Want me to start with a specific task or group — e.g., the A1→A10 auth chain, since that's the largest coherent block of Blocker findings?
