import { serve } from "std/http/server";
import {
  asString,
  corsHeaders,
  errorResponse,
  jsonResponse,
  readJson,
  requireUser,
  serviceClient,
} from "../_shared/http.ts";

type PaymentTransaction = {
  id: string;
  user_id: string;
  package_id: string;
  provider_reference: string;
  amount_minor: number;
  currency: string;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return errorResponse("Method not allowed.", 405);

  try {
    const body = await readJson(req);
    const admin = serviceClient();
    const manualVerify = body.manual_verify === true;

    if (!manualVerify) {
      const webhookSecret = Deno.env.get("FLUTTERWAVE_WEBHOOK_SECRET");
      if (webhookSecret && req.headers.get("verif-hash") !== webhookSecret) {
        return errorResponse("Invalid Flutterwave webhook signature.", 401);
      }
    }

    const authContext = manualVerify ? await requireUser(req) : null;
    const txRef = asString(body.tx_ref) ??
      asString((body.data as Record<string, unknown> | undefined)?.tx_ref);
    const transactionId = asString(body.transaction_id) ??
      asString((body.data as Record<string, unknown> | undefined)?.id);

    if (!txRef) return errorResponse("tx_ref is required.");
    if (!transactionId) return errorResponse("transaction_id is required.");

    const transactionQuery = admin
      .from("payment_transactions_r")
      .select("*")
      .eq("provider", "flutterwave")
      .eq("provider_reference", txRef)
      .single();

    const { data: transaction, error: txError } = await transactionQuery;
    if (txError || !transaction) {
      return errorResponse("Payment transaction not found.", 404);
    }

    const payment = transaction as PaymentTransaction;
    if (authContext && payment.user_id !== authContext.user.id) {
      return errorResponse(
        "Payment transaction does not belong to this user.",
        403,
      );
    }

    const { data: creditPackage, error: packageError } = await admin
      .from("credit_packages_r")
      .select("code,price_minor,currency")
      .eq("id", payment.package_id)
      .single();
    if (packageError || !creditPackage) {
      return errorResponse("Credit package not found.", 404);
    }

    const verified = await verifyFlutterwaveTransaction(transactionId);
    const verifiedData = typeof verified.data === "object" &&
        verified.data !== null
      ? verified.data as Record<string, unknown>
      : {};
    const status = String(verifiedData.status ?? "").toLowerCase();
    const verifiedTxRef = String(verifiedData.tx_ref ?? txRef);
    const amount = Number(verifiedData.amount ?? 0);
    const currency = String(verifiedData.currency ?? payment.currency)
      .toUpperCase();
    const expectedAmount = payment.amount_minor / 100;

    if (status !== "successful" || verifiedTxRef !== txRef) {
      await markFailed(admin, payment.id, transactionId, verified);
      return errorResponse("Flutterwave transaction is not successful.", 402);
    }
    if (
      currency !== payment.currency.toUpperCase() || amount < expectedAmount
    ) {
      await markFailed(admin, payment.id, transactionId, verified);
      return errorResponse(
        "Flutterwave transaction amount or currency mismatch.",
        402,
      );
    }

    const { data, error } = await admin.rpc("grant_purchase_credits", {
      p_user_id: payment.user_id,
      p_package_code: creditPackage.code,
      p_provider: "flutterwave",
      p_provider_reference: txRef,
      p_provider_transaction_id: transactionId,
      p_raw_payload: verified,
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

async function verifyFlutterwaveTransaction(
  transactionId: string,
): Promise<Record<string, unknown>> {
  const secretKey = Deno.env.get("FLUTTERWAVE_SECRET_KEY");
  if (!secretKey) throw new Error("FLUTTERWAVE_SECRET_KEY is not configured.");

  const response = await fetch(
    `https://api.flutterwave.com/v3/transactions/${
      encodeURIComponent(transactionId)
    }/verify`,
    {
      headers: {
        "Authorization": `Bearer ${secretKey}`,
        "Content-Type": "application/json",
      },
    },
  );
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(`Flutterwave verification failed with ${response.status}.`);
  }
  return payload as Record<string, unknown>;
}

async function markFailed(
  admin: ReturnType<typeof serviceClient>,
  paymentId: string,
  transactionId: string,
  rawPayload: Record<string, unknown>,
) {
  await admin
    .from("payment_transactions_r")
    .update({
      status: "failed",
      provider_transaction_id: transactionId,
      raw_payload: rawPayload,
    })
    .eq("id", paymentId);
}
