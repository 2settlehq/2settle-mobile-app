/// In-memory session data survives Back and PIN locking, without recreating a payment.
class TransferFlowCache {
  static final Map<String, Map<String, String>> _payments = {};
  static Map<String, String>? get(String key) => _payments[key];
  static void save(String key, Map<String, String> payment) {
    _payments[key] = Map.of(payment);
  }

  static void complete(String key) => _payments.remove(key);
}
