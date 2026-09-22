/// Native coins and tokens use different network identifiers in payment-engine.
String paymentNetworkCode({required String crypto, required String network}) {
  return switch (crypto.toUpperCase()) {
    'BTC' => 'bitcoin',
    'ETH' => 'ethereum',
    'BNB' => 'bsc',
    'TRX' => 'tron',
    _ => network.trim().toLowerCase(),
  };
}
