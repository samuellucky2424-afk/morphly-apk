module.exports = (req, res) => {
  res.status(200).json({
    name: 'Morphly API',
    status: 'ok',
    routes: [
      '/api/decart-token',
      '/api/flutterwave-webhook',
      '/api/morph-session',
      '/api/payment-options',
      '/api/store-purchase-verify',
    ],
  });
};
