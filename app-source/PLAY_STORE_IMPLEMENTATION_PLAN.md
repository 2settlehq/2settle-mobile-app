# 2Settle deployment and Play Store readiness plan

Updated September 25, 2026 from the current source, existing tests, and read-only public endpoint checks. This is the current status document; [the September 15 audit](PLAY_STORE_READINESS_AUDIT.md) remains historical evidence.

## Scope and evidence

- App and gateway: commit `1ff7c68` on `main`. `app-source` and `mobile-api` are sibling directories in the **same Git repository**, `2settle-mobile-app`; they have separate build/deployment workflows. The previous description of separate checkouts was incorrect.
- Backend: local `../../payment-engine/backend`, repository commit `e0afa31`. It is available for inspection. Its deployment revision and runtime settings were not verified; local backend code is not proof of production behavior.
- Source review and existing tests only, plus public HTTP GETs. No payment was created or claimed, no money moved, no deployment performed, and no signing secrets or production environment values inspected.
- No application/backend code changed during this update. Subsequent code fixes require an exact proposal and explicit approval under the user's code-change instructions.

Statuses: **Done (code)** = implemented and inspected, not necessarily deployed; **Partial** = implementation exists with remaining gaps; **Open** = unresolved; **External verification** = requires deployment/console/device/owner evidence.

## Results of this verification

| Check | Result on September 25 |
|---|---|
| Existing Node gateway tests | **24 passed, 0 failed** across bank resolution, error logging/redaction, estimates, and payment-request mapping. |
| Existing Flutter tests | **51 passed, 1 failed**. `test/widget_test.dart` fails with `[core/no-app] No Firebase App '[DEFAULT]' has been created`. Targeted rerun reproduced it. |
| Public gateway `GET /api/gifts/2S-6AWC8W/check` | **HTTP 404, Vercel `NOT_FOUND`**, plain text. This is a missing deployed route, not an `exists: false` gift response. Root cause in the Vercel project/build/domain settings remains unverified. |
| Public gateway `GET /api/rate` | **HTTP 200**, JSON `ok: true` with a numeric rate. This proves this route answered at check time, not long-term reliability. |
| Privacy and terms pages | Both returned **HTTP 200** with actual policy text. Content/ownership/mobile-app coverage still needs review (D4). |
| Release signing | `android/app/build.gradle` still uses `signingConfigs.debug`; `android/key.properties` absent. |
| Release identity/version | Release ID remains `com.sirfitech.settleio.original`; `pubspec.yaml` is `1.0.0+1`; splash label is `2Settle V2.36.38`. Play Console values not checked. |

Commands run from `app-source`:

```powershell
node --test test/bank_resolve.test.mjs test/error_logging.test.mjs test/mobile_api_estimate.test.mjs test/payment_request_gateway.test.mjs
flutter test --no-pub --reporter compact
flutter test --no-pub --reporter expanded test/widget_test.dart
```

No signed release build, 16 KB device test, full static analysis, backend test suite, or end-to-end money flow was run in this audit. The earlier 17 mocked gift checks were ad hoc verification during implementation, not a checked-in regression suite.

## A. Flutter app

Existing task IDs are retained for comparison with the historical audit.

| Task | Status | Work item | Current evidence and remaining acceptance criteria |
|---|---|---|---|
| A1 | Done (code) | Real sign-out | Settings and Dashboard call `AuthService.logout()` and navigate to Login. See `lib/pages/settings/settings_widget.dart:405`, `lib/pages/dashboard/dashboard_widget.dart:1230`, and `lib/services/auth_service.dart:105`. Account-data cleanup remains A2. |
| A2 | Partial | Clear account data on sign-out | `AuthService.clearSession()` removes tokens, cached profile, and login/phone identity. The device PIN and device ID are intentionally retained. However, globally keyed local transaction/gift/request histories remain, and Dashboard/History read those keys without account scoping. Verify and clear or scope all account-specific caches, including saved beneficiaries, before marking complete. Sources: `lib/services/auth_service.dart:256`, `lib/services/mobile_identity_service.dart`, `lib/pages/history/history_widget.dart:65`, `lib/pages/dashboard/dashboard_widget.dart:546`. |
| A3 | Done (code) | Secure PIN and retry lockout | `lib/services/pin_service.dart` stores a salted PBKDF2-HMAC-SHA256 hash in secure storage and implements escalating lockout after repeated failures. Dedicated PIN hashing/lockout regression coverage is still part of A15. |
| A4 | Done (code), behavior caveat | Validate session after PIN unlock | `confirm_code_widget.dart:112` calls `AuthService.validateSession()` and rejects a definitive invalid session. A `null` result (network/server uncertainty) still allows local unlock; this is not proof of current server authorization. Document/test the intended offline behavior in A15. |
| A5 | Partial | Route guards tied to the real session | 33 routes declare `requireAuth: true`. However, `nav.dart:54` still uses `(user?.loggedIn ?? false) || _appSessionActive`, and `main.dart` still subscribes to Firebase auth. The earlier claim that Firebase is no longer part of the guard was wrong. Resolve/test whether a legacy Firebase session can bypass the intended real-session/PIN gate, including after logout and on deep links. |
| A6 | Partial | Token refresh across authenticated flows | `AuthService.refreshAccessToken()` and `validateSession()` exist; phone-profile lookup also retries after refresh. Most payment/gift calls still obtain and send the current token directly without a shared 401-refresh/retry layer. Define safe retry behavior, coordinated with B6, and test expiry during an active flow. |
| A7 | Open; depends on C1 | In-app account deletion | No real delete-account UI/service was found. Backend deletion is also absent in the inspected user routes. Define deletion/retention behavior, implement it, then wire the app and public request path. |
| A8 | Done (current contract) | Match gateway authentication requirements | Gift creation and cancellation send bearer tokens; payment creation/claim/cancellation verify the end user in the gateway. Bank resolution is now deliberately callable without end-user auth (`mobile-api/api/banks/resolve.js`, `test/bank_resolve.test.mjs`); it uses server-side HMAC. The old assertion that bank resolution requires a bearer token is stale. Public-route abuse protection remains B2. |
| A9 | Done (code) | Secure token storage | Access/refresh tokens use `FlutterSecureStorage` in `lib/services/auth_service.dart`. |
| A10 | Done (code) | Validate session at splash | Contrary to the prior plan, `splash_screen_widget.dart:69` now calls `validateSession()` when a PIN exists and sends definitively invalid sessions to Login. Uncertain network results continue to PIN unlock. |
| A11 | Open | Finish/remove dead Settings actions | Currency Options, Support, and Invite Friends still have no action callback (`settings_widget.dart:633`). Product owner must choose working behavior or removal. |
| A12 | Open | Finish/remove KYC and Tier entries | Settings still displays placeholder notices for KYC and Tier level (`settings_widget.dart:414`). |
| A13 | Partial | Account linking | Real phone verification/linking now exists in `lib/services/payment_phone_service.dart` and the payment phone prompt, with tests. Security-page Wallet/Email/Google linking remains a placeholder; Phone is still displayed as statically linked (`security_widget.dart:244`). Complete these entries or accurately limit what is offered. |
| A14 | Open; console verification needed | Version metadata | Splash hardcodes `V2.36.38`, while `pubspec.yaml:18` is `1.0.0+1`. Confirm the production versionCode and update the build/display versions consistently. |
| A15 | Partial; suite currently fails | App regression coverage | Tests now cover estimates, crypto/network mapping, phone service/prompt, request creation, PIN resume, keypads, keyboard positioning, and logging. The statement that only a template test exists is obsolete. Repair/replace the failing Firebase-dependent smoke test and add complete login/logout, PIN lockout, route-guard, session-expiry, and gift lifecycle coverage. No `integration_test` directory was found. |
| A16 | Open; signing credentials needed | Release signing | `android/app/build.gradle:85` uses the debug key. The release-signing block exists but is not used, and `android/key.properties` is absent. Confirm/retrieve the registered upload key (or follow the owner's approved reset/new-key process), configure local/CI signing, and verify a signed AAB. Do not assume a new arbitrary key can update the existing listing. |
| A17 | External verification | Release package ID | Release adds `.original` to `com.sirfitech.settleio`. Confirm this against the existing Play Console app; do not remove the suffix without that evidence. |
| A18 | Open | Release lint | `android/app/build.gradle:54` still sets `checkReleaseBuilds false`. Enable it and resolve findings before release; preparation is not inherently blocked on receiving signing credentials. |
| A19 | Done (code) | Remove legacy storage flag | `requestLegacyExternalStorage` is absent from the current main Android manifest. |
| A20 | Done (code) | Remove dead bank API wrapper | The old `BankNameCheckCall` is absent from `lib/backend/api_requests/api_calls.dart`. |
| A21 | Done for centralization | Central app API configuration | Rate and bank URLs are in `lib/config/api_config.dart`. The bank list still uses `https://2settle.io/api/banks?...` directly; centralization is complete, migration to the gateway is not. Verify that endpoint/environment strategy before any further change. |
| A22 | Done (code); new since earlier plan | Preserve screen on PIN resume | `main.dart` pushes the resume PIN screen and returns to the existing navigation stack. `test/pin_resume_test.dart` passed, including Back blocking and form preservation. |
| A23 | Partial release verification; new | Payment requests and verified phone | Phone linking and payment requests are implemented; request links use the backend reference via `lib/services/payment_request_service.dart`. Corresponding Flutter/gateway tests passed. A real authenticated device flow through link creation, funding, history, and settlement is still unverified. |

## B. Mobile API gateway

Sources below are relative to `../mobile-api` unless specified otherwise.

| Task | Status | Work item | Current evidence and remaining acceptance criteria |
|---|---|---|---|
| B1 | Done (code); deployment blocked | Gift lookup and pre-claim eligibility | `lib/gift-lookup.js` calls `/v1/gifts/check?gift_id=...`; `api/gifts/[reference]/check.js` exposes only selected fields. `Claimed` blocks claiming; only `Not claimed` plus `Successful` is eligible. `claim/confirm.js` repeats the check, returning 409 for unavailable gifts and 502 if verification fails. This is bearer-code eligibility, not intended-recipient ownership. Deployment is D7; lifecycle integration is B10; concurrency protection is C6. |
| B2 | Open | Public gateway rate limiting | No gateway limiter found. Bank resolution, estimates, and gift lookups are publicly callable. Backend has an in-memory API-key/IP limiter, but that does not establish durable per-caller gateway throttling. Choose/configure an appropriate mechanism and verify limits across instances. |
| B3 | Done (code) | Redact payment-creation responses | `api/payments/index.js` uses an explicit success-field allowlist and no raw upstream/request echo. App contract extensions, including giftId, must preserve this restriction (B10). |
| B4 | Done (code); production setting unverified | Gate signing diagnostics | `lib/signing.js` exposes diagnostics only when `TWOSETTLE_DEBUG_DIAGNOSTICS=true`; error paths use that gate. Confirm production does not enable it. Missing-variable names are separately tracked in B8. |
| B5 | Done (code); one live check passed | Rate proxy | `api/rate.js` forwards `/v1/rate`; deployed `/api/rate` returned 200 and a numeric rate on September 25. Estimates and transfer/request creation are also present, but this GET is not an end-to-end payment validation. |
| B6 | Open | Payment-creation idempotency | No caller idempotency-key propagation/deduplication found in gateway payment creation. Backend watcher transaction deduplication is a different operation and does not close this task. Define stable keys and backend uniqueness/replay semantics with C3. |
| B7 | Partial | Gateway regression suite | Four Node test files live in `app-source/test`, importing the gateway; 24 tests passed. `mobile-api/package.json` still has no test script. Add repeatable CI execution and checked-in tests for gift lookup/claim, cancellation ownership, auth errors, timeouts, and idempotency. Earlier ad hoc gift checks do not replace these. |
| B8 | Open, now verified | Generic configuration errors | `api/payments/index.js`, `api/banks/resolve.js`, gift lookup/cancel/claim, and payment lookup still return `missing` objects naming environment variables. New gift-check route already uses a generic configuration error. Apply the intended generic-error contract consistently. |
| B9 | Open | Central upstream host configuration | `https://api.2settle.io` remains hardcoded in multiple route/helpers, including auth and new gift lookup. Centralize it with an explicit environment strategy. |
| B10 | Open; new integration finding | Separate gift IDs from payment references throughout lifecycle | The new eligibility route uses gift IDs. However, claim confirmation's `_checkStatus()` still calls `/api/gifts/:reference`, whose gateway forwards `/v1/payments/:reference`. Current backend distinguishes that lookup from `/v1/payments/gifts/:giftId`. Gift-created UI stores/shares the payment `reference` as `_giftCode` and has a local code fallback; gateway payment responses omit `giftId`. Agree the contract and preserve backend-issued giftId from funding through sharing, claiming, and polling. Do not map `Claimed` directly to payout completion. Verify with a funded gift whose giftId differs from its payment reference. |

## C. Payment-engine backend

The backend is now available at `../../payment-engine/backend`; these are actionable backend follow-ups, not tickets blocked by missing source. All source references here are under its `src/` directory.

| Task | Status | Work item | Evidence and remaining acceptance criteria |
|---|---|---|---|
| C1 | Open | Account deletion and retention behavior | No account-deletion endpoint found in `routes/user.routes.ts` or inspected user-auth services. Define authenticated deletion/request processing, retained financial records, and user-facing retention information; then complete A7. |
| C2 | Partial source verification | OTP, token rotation/revocation, HMAC and IP controls | OTPs are hashed with SHA-256, expire, and have attempt/cooldown checks (`services/user-auth/services/otp.service.ts`). Refresh tokens are hashed and rotated/revoked (`token.service.ts`). HMAC, IP allowlisting and rate-limit middleware are mounted in `index.ts`. Remaining verification: concurrent OTP/refresh replay, production flags/proxy trust, and session revocation semantics. Access-token verification is JWT-based; refresh revocation alone is not immediate access-token revocation. No production config or concurrency tests inspected/run. |
| C3 | Open | Deduplicate payment creation | No request idempotency-key handling found in `routes/payment.routes.ts`, payment creation schema, or session creation path. `processed-tx-store.ts` deduplicates watcher transactions only. Implement/test request-level deduplication with B6. |
| C4 | Partial operational verification | Deployed rate route | Gateway rate GET succeeded on September 25. Remaining: authenticated estimate/payment tests, upstream revision/configuration verification and operational monitoring; do not call a single GET proof of stability. |
| C5 | Source behavior confirmed | Gift claim semantics | Current `routes/payment.routes.ts:466` resolves by **giftId**, requires gift type and `confirmed` status, and rejects an existing receiver. Claim schema accepts bankCode/accountNumber; the recipient identity is not recorded at creation. The prior local code used payment reference; it has since changed. Verify this backend revision is deployed. B1's eligibility check is not recipient-identity enforcement. |
| C6 | Open review/test; new | Atomic gift claiming | Claim route reads status/receiver, resolves a bank account, then calls `setReceiverId`; the session manager performs a generic repository update. The gateway pre-check cannot make this sequence atomic. Verify concurrent claims and enforce a single receiver/payout transition if not already guaranteed deeper in the transaction/settlement path. No double payout was reproduced in this audit. |

## D. Deployment, store and owner actions

| Task | Status | Remaining action |
|---|---|---|
| D1 | Done for old code mismatch | Gift creation/cancellation bearer headers are present. Bank resolution now follows the intentionally public contract. Runtime smoke tests remain necessary; this does not certify all auth flows. |
| D2 | External verification | Confirm the existing Play Console package matches `com.sirfitech.settleio.original`. |
| D3 | External verification | Confirm the highest used versionCode and approved release version before building/uploading. |
| D4 | Partial | [Privacy](https://spend.2settle.io/privacy) and [terms](https://spend.2settle.io/terms) both serve actual text with HTTP 200. Privacy is dated August 20, 2026 and names 2SettleHQ; terms are dated September 15, 2026 and name The 2Settle Ltd. Have the owner reconcile entity/contact details and confirm native-app scope, collection/retention disclosures and deletion information. HTTP success is not a content/compliance sign-off. |
| D5 | External verification | Review/complete Play Console Data Safety, financial-feature declarations and country-specific distribution requirements against current policy and actual app behavior. No Console access or legal/policy certification was performed in this update. |
| D6 | External verification | Build a correctly signed AAB and verify 16 KB page-size compatibility on an appropriate device/emulator, including packaged native libraries. SDK/NDK settings alone are insufficient evidence. |
| D7 | Open deployment blocker; new | `/api/gifts/:reference/check` exists locally and is tracked in `1ff7c68`, but the production URL returned Vercel `NOT_FOUND`. Inspect the active production commit, project root (`mobile-api` for this repository), build output/functions, build errors and production-domain assignment. Verify a successful deployment and a JSON response from the exact URL the app uses. pnpm setup messages alone do not prove deployment success. |
| D8 | Open release validation; new | After code fixes and deployment, run the green automated suites and approved device/sandbox smoke tests for login/logout, refresh/PIN resume, transfer, request, gift funding/sharing/claim, cancellation, and final settlement/history. Verify account switching does not show another account's cached data. Record versions and results. No real-money test is authorized by this documentation update. |

## Recommended completion order

1. **D7:** diagnose and complete gateway deployment; verify the new gift-check route serves JSON.
2. **B10 / C5 / C6:** finish gift-ID lifecycle integration and verify the deployed backend contract and claim concurrency behavior.
3. **A2 / A5 / A6 / A15 / B7:** close session/cache isolation gaps, repair the failed smoke test, and extend regression coverage.
4. **A7 / C1 / A11-A13:** complete deletion and resolve unfinished UI entries; verify legal content with the owner.
5. **B2 / B6 / C2 / C3:** finish abuse/retry protections and backend auth/concurrency verification; complete B8/B9 configuration cleanup.
6. **A14 / A16-A18 / D2-D6 / D8:** finalize console identity, upload signing, lint/build versions, store declarations, and signed-device release checks.

Signing identity/credentials and console checks can proceed alongside code work. This plan does not authorize code changes or deployment; each proposed implementation must follow the user's approval preference.
