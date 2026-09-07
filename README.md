# 2Settle Mobile Developer Handoff

This package contains the source used by the current 2Settle Flutter mobile app and its supporting mobile API.

## Contents

- `app-source/` — Flutter application source, Android and iOS projects, app assets, Firebase files, and dependency manifests.
- `mobile-api/` — Vercel server-side proxy used by the app for payments, bank-account resolution, and gift operations.
- `reference-build/2Settle V2.36.38.apk` — latest available Android build for installation and visual/behavioral comparison.

## Start the Flutter app

1. Install a stable Flutter SDK compatible with Dart `>=3.0.0 <4.0.0`.
2. Open `app-source/` as the project root.
3. Run `flutter pub get`.
4. Run `flutter run` with an Android device/emulator or iOS simulator selected.

Do not edit generated folders such as `build/` or `.dart_tool/`; Flutter recreates them. The machine-specific `android/local.properties` file is intentionally excluded and will be generated/configured on the developer's machine.

## Mobile API

The app calls the deployed mobile API at `https://2settlemobile.vercel.app`. The source is in `mobile-api/`. Its deployment requires these environment variables, which are intentionally not stored in the source:

- `TWOSETTLE_API_KEY`
- `TWOSETTLE_SECRET_KEY`

## Release signing

No Android release signing keystore was found in the project. A developer can create and test debug builds from this package, but publishing an update under the existing Play Store app identity requires the existing release/upload signing credentials or the Play App Signing recovery process.
