# Morphly

Morphly is a Flutter iOS/Android app built from the included design handoff. It includes a polished splash screen, Supabase auth, the main AI camera flow, credits, hybrid payments, settings, and a secure backend boundary for Decart realtime sessions.

## What Is Implemented

- Flutter UI for splash, login/create account, camera/upload/start, purchase credits, and settings.
- Shared Morphly design tokens from `morphly/DESIGN.md`.
- Supabase schema with RLS, storage buckets, and Morphly-specific `_r` tables for profiles, settings, credit packages, append-only credit ledger, morph sessions, and payment transactions.
- Edge Functions for Decart token minting, morph-session reserve/finalize/refund, Flutterwave payment setup/webhook verification, and store purchase verification placeholder.
- A local Flutter plugin package, `packages/decart_realtime_bridge`, exposing `startSession`, `setPrompt`, `stopSession`, and realtime events for Android/iOS Decart SDK integration.

## Local Setup

1. Install Flutter and Dart.
2. Generate the missing native platform wrappers:

   ```sh
   flutter create . --platforms=android,ios
   ```

3. Install packages:

   ```sh
   flutter pub get
   ```

4. Copy `.env.example` to `.env`, then run with the local dart-define file:

   ```sh
   flutter run --dart-define-from-file=.env
   ```

   On this Windows machine, `tool/build_debug_apk.ps1` also builds the debug APK with `.env` and the local JDK/Flutter paths.

5. Apply the native launch color after platform wrappers exist:

   ```sh
   dart run flutter_native_splash:create
   ```

The app includes the Morphly Supabase project URL and anon key as defaults. `.env` can still override them for another environment.

See `docs/native_platform_setup.md` for Android permissions, iOS `Info.plist` keys, StoreKit/Play Billing product IDs, and Decart SDK hook points.

## Supabase Setup

1. Install and log in to the Supabase CLI.
2. Link a project or run locally.
3. Apply migrations:

   ```sh
   supabase db push
   ```

4. Set secrets from `supabase/.env.example`:

   ```sh
   supabase secrets set --env-file supabase/.env
   ```

5. Deploy functions:

   ```sh
   supabase functions deploy morph-session
   supabase functions deploy decart-token
   supabase functions deploy payment-options
   supabase functions deploy flutterwave-webhook
   supabase functions deploy store-purchase-verify
   ```

## Native Decart Bridge

The Flutter plugin exposes the app contract now, and the native Android/iOS files include the exact production hook points. To complete realtime rendering:

- Android: add the official Decart Android dependency in `packages/decart_realtime_bridge/android/build.gradle`, initialize the Decart client with the short-lived token, attach the camera/WebRTC track, and expose remote frames through a PlatformView.
- iOS: add the official Decart Swift package in Xcode, initialize the client with the short-lived token, attach camera/WebRTC, and expose the renderer through a PlatformView.

The permanent Decart API key stays only in Supabase secrets. The app receives short-lived client tokens from `decart-token`.

## Payments

- Flutterwave is the preferred app payment channel when `FLUTTERWAVE_ENABLED=true` and the package permits it.
- The Flutter app calls backend endpoints through `VERCEL_API_BASE_URL` when provided, with Supabase Edge Functions retained as a local-development fallback.
- Credit grants happen only after server-side verification and write to an idempotent ledger.
- `STORE_VERIFICATION_MODE=strict` rejects store purchase verification until Apple App Store Server API and Google Play Developer API verification are wired. Use `sandbox_accept` only for local sandbox testing.

## Verification

Run these once Flutter/Dart are installed:

```sh
flutter analyze
flutter test
```

iOS builds require macOS or CI with Xcode.
