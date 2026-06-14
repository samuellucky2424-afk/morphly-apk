const allowedFunctions = new Set([
  'decart-token',
  'flutterwave-webhook',
  'morph-session',
  'payment-options',
  'store-purchase-verify',
]);

function applyCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'authorization, content-type, verif-hash',
  );
}

function normalizeBody(body) {
  if (body == null) return '{}';
  if (Buffer.isBuffer(body)) return body.toString('utf8');
  if (typeof body === 'string') return body.length === 0 ? '{}' : body;
  return JSON.stringify(body);
}

async function proxySupabaseFunction(req, res, functionName) {
  applyCors(res);

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed.' });
    return;
  }

  if (!allowedFunctions.has(functionName)) {
    res.status(404).json({ error: 'Unknown Morphly API route.' });
    return;
  }

  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseAnonKey) {
    res.status(500).json({
      error:
        'Vercel backend is missing SUPABASE_URL or SUPABASE_ANON_KEY.',
    });
    return;
  }

  const endpoint = `${supabaseUrl.replace(/\/+$/, '')}/functions/v1/${functionName}`;
  const headers = {
    apikey: supabaseAnonKey,
    authorization: req.headers.authorization || `Bearer ${supabaseAnonKey}`,
    'content-type': req.headers['content-type'] || 'application/json',
  };

  if (req.headers['verif-hash']) {
    headers['verif-hash'] = req.headers['verif-hash'];
  }

  const response = await fetch(endpoint, {
    method: 'POST',
    headers,
    body: normalizeBody(req.body),
  });

  const text = await response.text();
  res.status(response.status);
  res.setHeader(
    'content-type',
    response.headers.get('content-type') || 'application/json',
  );
  res.send(text);
}

module.exports = { proxySupabaseFunction };
