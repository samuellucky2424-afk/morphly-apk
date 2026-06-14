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
    const mode = Deno.env.get("STORE_VERIFICATION_MODE") ?? "strict";
    const platform = asString(body.platform);
    const packageCode = asString(body.package_code);
    const productId = asString(body.product_id);
    const purchaseId = asString(body.purchase_id) ?? productId;
    const verificationData = asString(body.verification_data);

    if (
      !platform || !packageCode || !productId || !purchaseId ||
      !verificationData
    ) {
      return errorResponse("Missing store purchase verification fields.");
    }
    if (!["ios", "android"].includes(platform)) {
      return errorResponse("Unsupported store platform.");
    }

    if (mode !== "sandbox_accept") {
      return errorResponse(
        "Store purchase verification is not configured. Wire Apple App Store Server API and Google Play Developer API before production.",
        501,
      );
    }

    const provider = platform === "ios" ? "apple" : "google";
    const { data, error } = await admin.rpc("grant_purchase_credits", {
      p_user_id: user.id,
      p_package_code: packageCode,
      p_provider: provider,
      p_provider_reference: `${platform}:${purchaseId}`,
      p_provider_transaction_id: purchaseId,
      p_raw_payload: {
        mode,
        product_id: productId,
        verification_data: verificationData,
      },
    });

    if (error) throw error;
    return jsonResponse(Array.isArray(data) ? data[0] : data);
  } catch (error) {
    return errorResponse(
      error instanceof Error ? error.message : String(error),
      500,
    );
  }
});
