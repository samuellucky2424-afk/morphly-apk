import { serve } from "std/http/server";
import {
  asNumber,
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
    const { client } = await requireUser(req);
    const action = asString(body.action);

    if (action === "reserve") {
      const referenceImagePath = asString(body.reference_image_path);
      if (!referenceImagePath) {
        return errorResponse("reference_image_path is required.");
      }

      const { data, error } = await client.rpc("reserve_morph_session", {
        p_reference_image_path: referenceImagePath,
        p_estimated_seconds: asNumber(body.estimated_seconds, 30),
        p_model: asString(body.model),
      });
      if (error) throw error;
      return jsonResponse(Array.isArray(data) ? data[0] : data);
    }

    if (action === "finalize") {
      const sessionId = asString(body.session_id);
      if (!sessionId) return errorResponse("session_id is required.");

      const { data, error } = await client.rpc("finalize_morph_session", {
        p_session_id: sessionId,
        p_elapsed_seconds: asNumber(body.elapsed_seconds, 1),
      });
      if (error) throw error;
      return jsonResponse(Array.isArray(data) ? data[0] : data);
    }

    if (action === "refund") {
      const sessionId = asString(body.session_id);
      if (!sessionId) return errorResponse("session_id is required.");

      const { data, error } = await client.rpc("refund_morph_session", {
        p_session_id: sessionId,
      });
      if (error) throw error;
      return jsonResponse(Array.isArray(data) ? data[0] : data);
    }

    return errorResponse("Unsupported morph-session action.");
  } catch (error) {
    return errorResponse(
      error instanceof Error ? error.message : String(error),
      500,
    );
  }
});
