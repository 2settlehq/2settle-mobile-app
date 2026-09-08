# 2Settle mobile app audit

Date: 2026-09-07

**Assessment: the reviewed source is not ready for production payment use.** Authentication and recovery are incomplete, API operations lack caller authorization, and some payment flows simulate confirmation. This assessment concerns this checkout; deployed infrastructure and the upstream payment engine were not inspected.

Scope: Flutter authentication, navigation, send/receive/gift flows, local persistence, mobile API handlers, Firebase rules/functions, Android/iOS configuration, and existing tests. Application source was not changed. This is a source audit with offline API reproductions, not a device penetration test or a dependency vulnerability scan.

## Findings, ordered by priority

### 1. Critical — API signs anonymous payment and cancellation requests

Evidence: `mobile-api/api/payments/index.js:94`, `mobile-api/api/gifts/[reference]/cancel/index.js:89`, `mobile-api/api/gifts/[reference]/claim/confirm.js:183`, and `mobile-api/api/banks/resolve.js:158`.

Handlers check HTTP method, server credentials, and some request fields, but do not authenticate the caller. Cancellation accepts a reference without checking sender ownership. Creation accepts caller-supplied payer identifiers. The proxy then adds the application's upstream key and signature. Claim accepts only a reference and destination bank details. There is no in-repository middleware or rate limiter establishing another authorization boundary.

Impact: someone who reaches these handlers can make signed upstream requests without an app session. A gift recipient who knows the reference can attempt sender-only cancellation. The upstream service may enforce additional business rules, but this proxy supplies no authenticated end-user identity with which to establish ownership. Actual production cancellation or fund movement was not attempted.

Verification: offline mocks confirmed anonymous create, cancel, and claim requests reach signed upstream fetches. Bearer-reference claiming may be intentional; sender-only cancellation and identity-bound creation still require independent authorization.

Fix: validate a server-issued session, derive payer identity from that session, enforce ownership for lookup/cancellation, and define explicit claim authorization. Apply rate limits to public lookup, claim, and bank-resolution operations.

### 2. Critical — OTP confirmation and forgotten-PIN recovery accept unverified input

Evidence: `app-source/lib/pages/login/login_widget.dart:557`, `app-source/lib/pages/confirm_code/confirm_code_widget.dart:69`, and `app-source/lib/pages/set_app_passcode/set_app_passcode_widget.dart:170`.

Login waits and saves a phone number locally, without requesting an OTP. `_confirmCode()` validates input only in `unlock` mode; confirmation and recovery mark themselves successful after delays. Recovery routes to PIN reset, which overwrites the stored PIN without a verified recovery session.

Reproduction from source: unlock screen → Forgot pin → continue through login → submit an arbitrary confirmation code → choose a new PIN → unlock with the new PIN. This bypasses the existing PIN on that installation; it does not demonstrate takeover of a separate upstream account.

Fix: implement actual OTP issuance/verification and server-backed sessions. Require a short-lived verified recovery grant before changing the PIN. Do not save a claimed phone as verified identity.

### 3. Critical — Funding confirmation and receipts can be produced without payment

Evidence: `app-source/lib/pages/receive_funding/receive_funding_widget.dart:125`, `:400`, and `app-source/lib/pages/confirmation_page/confirmation_page_widget.dart:61`.

`_confirmFunding()` advances through three timed stages without contacting a server. The completed animation is included in the `funded` condition, so the gift screen can state that funding was detected without evidence. The ordinary send flow proceeds to a confirmation screen and a receipt whose status is hard-coded to Confirmed, with a locally generated reference. The screen also says settlement is processing (`confirmation_page_widget.dart:566`).

Impact: users can see or share apparent proof of payment when nothing was funded or settled. Gift claim polling elsewhere does not validate this funding animation or the ordinary send receipt.

Fix: drive funding, settlement status, and receipt contents exclusively from a server payment record. A check button should query status and preserve pending/unknown states until confirmed.

### 4. High — Ordinary send flow displays demo deposit addresses

Evidence: `app-source/lib/confirm_transaction/confirm_transaction_widget.dart:326` and `app-source/lib/pages/receive_funding/receive_funding_widget.dart:72`.

Confirming an ordinary send only saves a local transaction and navigates to funding; it does not create a backend payment or pass a deposit address. Funding falls back to literal addresses containing `2SettleDemo`. Those values are displayed, encoded as QR codes, and copied as wallet destinations. The gift-creation path can supply a real backend address, but the fallback also masks missing gift response data.

Impact: the standard send flow cannot reliably accept funding or associate it with the beneficiary. Several fallback values are visibly placeholders rather than usable wallet addresses.

Fix: create a payment server-side before presenting funding instructions. Require a valid address, payment reference, supported network, and expiry from the response; block the flow when these are absent.

### 5. High — Deep-linked routes bypass the local lock screen

Evidence: `app-source/lib/flutter_flow/nav/nav.dart:543`, `:882`, `:904`, and `app-source/android/app/src/main/AndroidManifest.xml` (deep-link intent filter). iOS also enables the `settleio` scheme in `ios/Runner/Info.plist`.

Routes, including Dashboard, use `requireAuth = false`; no route enables the existing authentication requirement. The PIN check is implemented only as a splash-screen navigation step. A direct route has no authenticated or unlocked-session check. No application lifecycle relock handling was found in the app entry point or pages.

Impact: direct navigation to a protected route can bypass the screen-level PIN gate and expose local history/account data. Device-level deep-link behavior remains to be verified on Android/iOS.

Fix: enforce both authenticated and unlocked session state centrally in routing, protect PIN setup/reset, and relock on the chosen background timeout. Test cold and warm deep links.

### 6. High — Shared hard-coded payer identity is used when identity is missing

Evidence: `mobile-api/api/payments/index.js:74` and `app-source/lib/services/mobile_identity_service.dart:8`.

The API fills in a fixed chat ID and phone when payer fields are missing. The app also supplies a fixed phone when no phone is stored. Its mobile ID is generated locally and cannot serve as proof of account ownership.

Impact: incomplete onboarding can attribute a payment to an unrelated fixed identity. A caller can also choose arbitrary identity strings, as confirmed by the offline reproduction. Notification and accounting consequences depend on how the upstream service uses these fields.

Fix: reject missing verified identity and derive identity from the authenticated account. Remove production fallback personal identifiers.

### 7. High — Receive links are generated without registering a backend request

Evidence: `app-source/lib/pages/pay_page/pay_page_widget.dart:304` and `app-source/lib/pages/receive_request_details/receive_request_details_widget.dart:153`.

Creation generates an `RCV-<local timestamp>` ID and saves the amount, destination, expiry, and usage only in SharedPreferences. It then exposes a URL at `https://receive.2settle.io/pay/<id>`. This code never sends the request record to that service. The status menu can advance through opened/part-paid/paid using delays and local writes.

Impact: the shared link contains no backend-registered payment instructions from this flow, and a locally marked paid state is not evidence of settlement. The external receive website was not probed; no claim is made about its current HTTP response.

Fix: persist requests on the server and use its returned link and ID. Read payment status from server events. If manual bookkeeping is intended, label it explicitly and keep it separate from verified payment status.

### 8. Medium — Change PIN is blocked by validation of a hidden empty controller

Evidence: `app-source/lib/pages/set_app_passcode/set_app_passcode_widget.dart:99`, `:113`, `:460`, and `set_app_passcode_model.dart:12`.

`_setPin()` checks `_model.pinCodeController` length before entering change mode. That controller is initialized empty. Change mode renders three different controllers for old/new/confirmation PINs, so filling those fields never satisfies the earlier check.

Reproduction from source: Security → Change app passcode → fill all three fields correctly → Save Pin. The handler returns at the hidden-controller length check instead of saving.

Fix: move setup-PIN validation into the setup/reset branch and validate only the three change controllers in change mode. Add a regression test for both 4- and 6-digit PINs.

### 9. Medium — PIN is stored in plaintext with no attempt lockout

Evidence: `app-source/lib/pages/set_app_passcode/set_app_passcode_widget.dart:155`, `:170`, and `app-source/lib/pages/confirm_code/confirm_code_widget.dart:83`.

The PIN is stored as an ordinary SharedPreferences string and compared directly. Failed unlock attempts only display a notice; no persistent retry limit or lockout is implemented.

Impact: access to the app's preference data exposes the PIN, and repeated unlock attempts remain available. This is a local-data protection issue, separate from the recovery bypass above; it is not a claim that unrelated apps can normally read the sandbox.

Fix: use platform-protected secret storage, an appropriate PIN verifier, and persistent throttling. Avoid using a short local PIN as the sole authorization for server-side money movement.

### 10. Medium — Public lookup forwards the unrestricted upstream object

Evidence: `mobile-api/api/gifts/[reference].js:209`.

The response includes the whole upstream `data`, `gift`, or `result` object under `gift`, beyond the normalized public fields. The endpoint requires only a six-character reference and has no application rate limit. The offline fixture confirmed nested payer data is returned unchanged.

Impact: any private fields included by the upstream response become public through this handler. Actual production response contents were not retrieved, so exposure of any particular real field is unverified.

Fix: return an explicit minimal field allowlist, authorize private details, and rate-limit reference lookups. Use a separate sufficiently strong claim token if references are intended for public receipts.

### 11. Medium — Non-finite amounts pass API validation

Evidence: `mobile-api/api/payments/index.js:68` and `:114`.

`fiatAmount: "Infinity"` becomes positive Infinity, passes the nonzero/positive test, and serializes to `null` in the signed request. The offline reproduction confirmed this behavior. Type, supported currency/network combinations, maximum amount, and amount precision are also not fully validated here.

Fix: enforce a strict request schema, finite bounded amounts, and explicit precision rules before signing. Do not rely on upstream rejection for input validation.

## Other release and reliability gaps

- Android release builds use `signingConfigs.debug` and an `.original` application ID suffix (`app-source/android/app/build.gradle:81`). This is a development release configuration. Verify the intended store identity and configure the actual upload signing key before distribution; existing store identity was not independently checked.
- Creation has a 14-second client timeout, but no idempotency key or retry reconciliation in the proxy (`create_gift_widget.dart:244`, `mobile-api/api/payments/index.js:134`). If creation succeeds upstream and the response is lost, another attempt can create another payment unless the upstream deduplicates independently. Upstream behavior is unknown.
- API fetches have no explicit deadlines. A stalled upstream can hold a function until platform termination.
- History and receive records are installation-local, and ordinary send history is truncated to 50 records (`confirm_transaction_widget.dart:322`). No authenticated server history recovery path was found. Clearing app data or changing devices can lose the only local record of these references.
- `app-source/lib/main.dart:101` clamps text scaling to 1.0, preventing users' larger-text settings from affecting the interface.
- Storage rules make every `/users/{userId}/...` object publicly readable (`app-source/firebase/storage.rules:8`). No active sensitive upload flow was established; confirm that this namespace contains only intentionally public assets. Firestore user rules do restrict documents to their owner.
- The only Flutter test is a widget-pump scaffold with no assertions (`app-source/test/widget_test.dart:13`). It does not initialize/mock Firebase before constructing the app. No API test script or CI configuration was found.

## Verification and limits

- `node audit/api-reproduction.mjs`: six offline reproductions passed, confirming current unsafe behavior. Fetch is replaced with a mock and only dummy credentials are used; passing is not a security pass.
- `node --check`: passed for all five mobile API handlers and both Firebase function JavaScript files.
- `flutter analyze --no-pub`: attempted but produced no result and was stopped. This checkout has no `.dart_tool/package_config.json`; Flutter dependency resolution, analysis, tests, and builds remain unverified. No analyzer success is claimed.
- No production API calls, payment transactions, deployment changes, or real credential use were performed.
- No device UI, accessibility, performance, deployed Firebase rules, upstream authorization, signing credentials, or dependency advisory database verification was performed.

## Recommended order of work

1. Block simulated payment confirmation and demo funding destinations from release builds.
2. Implement verified login/recovery and authenticated API ownership checks, then protect navigation.
3. Connect ordinary send and receive request flows to authoritative backend payment records.
4. Fix PIN changes/storage, restrict public response fields, validate amounts, and add idempotent creation.
5. Add tests for rejected anonymous/foreign-owner requests, OTP recovery, deep links, unfunded receipts, timeouts, PIN changes, and receive-link persistence. Resolve Flutter dependencies and complete analyzer, device, and release-build checks.
