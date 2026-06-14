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
    const sessionId = asString(body.session_id);
    const model = asString(body.model) ?? Deno.env.get("DECART_MODEL") ??
      "lucy-latest";
    if (!sessionId) return errorResponse("session_id is required.");

    const { data: session, error: sessionError } = await admin
      .from("morph_sessions_r")
      .select("id,user_id,status")
      .eq("id", sessionId)
      .eq("user_id", user.id)
      .single();

    if (sessionError || !session) {
      return errorResponse("Morph session not found.", 404);
    }
    if (!["reserved", "live"].includes(session.status)) {
      return errorResponse("Morph session cannot start from this state.", 409);
    }

    const tokenUrl = Deno.env.get("DECART_CLIENT_TOKEN_URL");
    const apiKey = Deno.env.get("DECART_API_KEY");
    if (!tokenUrl || !apiKey) {
      return errorResponse(
        "Decart token minting is not configured. Set DECART_CLIENT_TOKEN_URL and DECART_API_KEY.",
        501,
      );
    }

    const decartResponse = await fetch(tokenUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        session_id: sessionId,
        user_id: user.id,
        ttl_seconds: 600,
        scopes: ["realtime"],
      }),
    });

    const payload = await decartResponse.json().catch(() => ({}));
    if (!decartResponse.ok) {
      return errorResponse(
        `Decart token request failed with ${decartResponse.status}.`,
        502,
      );
    }

    const token = payload.apiKey ?? payload.api_key ?? payload.client_token ??
      payload.token;
    if (typeof token !== "string" || token.length === 0) {
      return errorResponse(
        "Decart token response did not include a token.",
        502,
      );
    }

    const expiresAt = typeof payload.expiresAt === "string"
      ? payload.expiresAt
      : typeof payload.expires_at === "string"
      ? payload.expires_at
      : new Date(Date.now() + 10 * 60 * 1000).toISOString();

    await admin
      .from("morph_sessions_r")
      .update({ status: "live", model })
      .eq("id", sessionId)
      .eq("user_id", user.id);

    return jsonResponse({ apiKey: token, expiresAt, model });
  } catch (error) {
    return errorResponse(
      error instanceof Error ? error.message : String(error),
      500,
    );
  }
});
