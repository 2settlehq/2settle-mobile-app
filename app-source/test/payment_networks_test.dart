import 'package:flutter_test/flutter_test.dart';
import 'package:settleio/data/payment_networks.dart';

void main() {
  for (final (crypto, network, expected) in [
    ('TRX', 'Tron', 'tron'),
    ('BNB', 'Binance', 'bsc'),
    ('BTC', 'Bitcoin', 'bitcoin'),
    ('ETH', 'Ethereum', 'ethereum'),
    ('USDT', 'TRC20', 'trc20'),
    ('USDT', 'BEP20', 'bep20'),
    ('USDT', 'ERC20', 'erc20'),
    ('USDC', 'BEP20', 'bep20'),
    ('USDC', 'ERC20', 'erc20'),
  ]) {
    test('$crypto on $network uses the backend identifier $expected', () {
      expect(paymentNetworkCode(crypto: crypto, network: network), expected);
    });
  }
}
