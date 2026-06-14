# Morphly Architecture

## App Flow

Morphly boots into the upgraded Flutter splash screen, checks Supabase session state, and routes to login or the camera. Login uses Supabase email/password auth. The camera screen lets the user select a reference image, uploads it to private Supabase Storage, reserves credits, asks the backend for a short-lived Decart token, then starts the native Decart realtime bridge.

## Credit Flow

Credits are never mutated directly by the app. The database uses an append-only `credit_ledger` and SQL RPCs:

- `reserve_morph_session` deducts a short session reservation.
- `finalize_morph_session` completes the session and refunds unused reserved credits.
- `refund_morph_session` returns reserved credits when startup fails.
- `grant_purchase_credits` adds verified purchases idempotently.

The first pricing rule is one credit per started 10 seconds, capped by the reserved amount for the session.

## Payments

The app chooses a channel per package:

- iOS with `apple_product_id`: Apple in-app purchase.
- Android with `google_product_id`: Google Play Billing.
- Flutterwave only when the package and backend release channel allow it.

Flutterwave transaction references are created server-side by `payment-options`. Webhooks and manual verification call Flutterwave's transaction verification API before granting credits.

## Security Boundary

The mobile app contains only public Supabase anon configuration. Supabase Edge Functions hold Decart, Flutterwave, and future Apple/Google server credentials. RLS restricts user data, and service-role writes happen only inside Edge Functions.
