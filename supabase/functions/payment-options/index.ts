import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  asString,
  corsHeaders,
  errorResponse,
  jsonResponse,
  readJson,
  requireUser,
} from "../_shared/http.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return errorResponse("Method not allowed.", 405);

  try {
    const body = await readJson(req);
    const { user, admin } = await requireUser(req);
    const channel = asString(body.channel);
    const packageCode = asString(body.package_code);

    if (channel !== "flutterwave") {
      return errorResponse("Only Flutterwave payment options are served here.");
    }
    if (!packageCode) return errorResponse("package_code is required.");

    if (Deno.env.get("FLUTTERWAVE_ENABLED") !== "true") {
      return errorResponse(
        "Flutterwave is disabled for this release channel.",
        403,
      );
    }

    const publicKey = Deno.env.get("FLUTTERWAVE_PUBLIC_KEY");
    if (!publicKey) {
      return errorResponse("Flutterwave public key is not configured.", 501);
    }

    const { data: creditPackage, error: packageError } = await admin
      .from("credit_packages_r")
      .select("*")
      .eq("code", packageCode)
      .eq("active", true)
      .single();

    if (packageError || !creditPackage) {
      return errorResponse("Credit package not found.", 404);
    }
    if (!creditPackage.flutterwave_enabled) {
      return errorResponse("Flutterwave is not enabled for this package.", 403);
    }

    const txRef = `morphly-${crypto.randomUUID()}`;
    const { error: txError } = await admin.from("payment_transactions_r").insert({
      user_id: user.id,
      package_id: creditPackage.id,
      provider: "flutterwave",
      provider_reference: txRef,
      status: "pending",
      amount_minor: creditPackage.price_minor,
      currency: creditPackage.currency,
      raw_payload: { source: "payment-options" },
    });

    if (txError) throw txError;

    return jsonResponse({
      flutterwave_public_key: publicKey,
      tx_ref: txRef,
      redirect_url: Deno.env.get("FLUTTERWAVE_REDIRECT_URL") ??
        "morphly://payment-callback",
      payment_options: Deno.env.get("FLUTTERWAVE_PAYMENT_OPTIONS") ??
        "card, banktransfer, ussd",
      test_mode: Deno.env.get("FLUTTERWAVE_TEST_MODE") !== "false",
    });
  } catch (error) {
    return errorResponse(
      error instanceof Error ? error.message : String(error),
      500,
    );
  }
});
