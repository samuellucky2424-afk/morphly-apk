const { proxySupabaseFunction } = require('./_proxy');

module.exports = (req, res) => proxySupabaseFunction(req, res, 'morph-session');
