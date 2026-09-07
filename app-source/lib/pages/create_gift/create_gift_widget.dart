import '/components/status_action_button.dart';
import '/components/top_notice.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/mobile_identity_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class CreateGiftWidget extends StatefulWidget {
  const CreateGiftWidget({super.key});

  static String routeName = 'CreateGift';
  static String routePath = 'createGift';

  @override
  State<CreateGiftWidget> createState() => _CreateGiftWidgetState();
}

class _CreateGiftWidgetState extends State<CreateGiftWidget> {
  static const _blue = Color(0xFF4472C4);
  static const _paymentsUrl = 'https://2settlemobile.vercel.app/api/payments';
  final _amountController = TextEditingController(text: '5000');
  String _crypto = 'USDT';
  String _network = 'TRC20';
  String _payWith = 'Crypto';
  bool _creating = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatAmount(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
    final fixed = parsed.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var index = 0; index < fixed.length; index++) {
      final remaining = fixed.length - index;
      buffer.write(fixed[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return '₦${buffer.toString()}';
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      labelStyle: FlutterFlowTheme.of(context).bodySmall.override(
            color: _blue.withValues(alpha: .9),
            fontSize: 12.4,
            letterSpacing: 0,
            fontWeight: FontWeight.w700,
          ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _blue.withValues(alpha: .16)),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _blue),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _amountCard(String value) {
    final theme = FlutterFlowTheme.of(context);
    final selected = _amountController.text == value;
    return Expanded(
      child: InkWell(
        onTap: () => safeSetState(() => _amountController.text = value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 68,
          padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 8, 8),
          decoration: BoxDecoration(
            color: selected ? _blue : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _blue : _blue.withValues(alpha: .14),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: selected ? 16 : 10,
                color: selected
                    ? _blue.withValues(alpha: .22)
                    : const Color(0x10000000),
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatAmount(value),
                style: GoogleFonts.inter(
                  color: selected ? Colors.white : _blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Gift',
                style: theme.bodySmall.override(
                  color: selected
                      ? Colors.white.withValues(alpha: .78)
                      : theme.secondaryText,
                  fontSize: 10,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cryptoFundingCard() {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_bitcoin_rounded,
                color: _blue, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay with crypto',
                  style: theme.bodyMedium.override(
                    color: theme.primaryText,
                    fontSize: 12.4,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fund this gift with $_crypto before a gift ID is created.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.override(
                    color: theme.secondaryText,
                    fontSize: 10.5,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _selectedNetwork {
    if (_crypto == 'USDT') return _network;
    return switch (_crypto) {
      'BTC' => 'Bitcoin',
      'ETH' => 'Ethereum',
      'BNB' => 'Binance',
      'TRX' => 'Tron',
      _ => 'Native',
    };
  }

  String get _selectedNetworkForApi {
    final network = _selectedNetwork.toLowerCase();
    return switch (network) {
      'bitcoin' => 'bitcoin',
      'ethereum' => 'ethereum',
      'binance' => 'bep20',
      'tron' => 'trc20',
      _ => network,
    };
  }

  String _formatCryptoAmount(dynamic value, String crypto) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse('${value ?? ''}'.replaceAll(',', '').trim());
    if (parsed == null) return '0.00000 $crypto';
    final roundedDown = (parsed * 100000).floor() / 100000;
    return '${roundedDown.toStringAsFixed(5)} $crypto';
  }

  Map<String, dynamic> _paymentFromResponse(Map<String, dynamic> payload) {
    final payment = payload['payment'];
    if (payment is Map) return Map<String, dynamic>.from(payment);
    final data = payload['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return payload;
  }

  Future<void> _continueToFunding() async {
    if (_creating) return;
    final amount = _amountController.text.replaceAll(',', '').trim();
    final parsedAmount = double.tryParse(amount) ?? 0;
    if (amount.isEmpty || parsedAmount <= 0) {
      showTopNotice(context,
          message: 'Enter a valid gift amount.', type: TopNoticeType.caution);
      return;
    }
    if (_payWith != 'Crypto') {
      showTopNotice(
        context,
        message: 'Create gift currently supports crypto funding.',
        type: TopNoticeType.caution,
      );
      return;
    }

    safeSetState(() => _creating = true);
    try {
      final mobileId = await MobileIdentityService.getOrCreateMobileId();
      final phone = await MobileIdentityService.getPhone();
      final response = await http
          .post(
            Uri.parse(_paymentsUrl),
            headers: const {
              'accept': 'application/json',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'type': 'gift',
              'fiatAmount': parsedAmount.round(),
              'chargeFrom': 'crypto',
              'fiatCurrency': 'NGN',
              'crypto': _crypto,
              'network': _selectedNetworkForApi,
              'payer': {
                'chatId': mobileId,
                'phone': phone,
              },
            }),
          )
          .timeout(const Duration(seconds: 14));
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      final ok = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['ok'] != false;
      if (!ok) {
        final message = decoded['message'] ??
            decoded['error'] ??
            'Unable to create gift payment.';
        throw Exception(message);
      }
      final payment = _paymentFromResponse(decoded);
      final crypto = '${payment['crypto'] ?? _crypto}'.toUpperCase();
      final network = '${payment['network'] ?? _selectedNetwork}'.toUpperCase();
      final fiatAmount = '${payment['fiatAmount'] ?? amount}';
      final reference = '${payment['reference'] ?? ''}';
      if (!mounted) return;
      context.pushNamed(
        ReceiveFundingWidget.routeName,
        queryParameters: {
          'settlementAmount': fiatAmount,
          'cryptoAmount': _formatCryptoAmount(payment['cryptoAmount'], crypto),
          'crypto': crypto,
          'network': network,
          'beneficiaryName': 'Created gift',
          'bankName': 'Gift',
          'accountNumber': '',
          'rate': '${payment['rate'] ?? 'Gift'}',
          'purpose': 'create_gift',
          'paymentId': '${payment['id'] ?? ''}',
          'reference': reference,
          'depositAddress': '${payment['depositAddress'] ?? ''}',
          'paymentStatus': '${payment['status'] ?? 'pending'}',
          'expiresAt': '${payment['expiresAt'] ?? ''}',
          'chargeFiat':
              '${payment['charge'] is Map ? payment['charge']['fiat'] ?? '' : ''}',
          'chargeCrypto':
              '${payment['charge'] is Map ? payment['charge']['crypto'] ?? '' : ''}',
          'transactionUsd': '${payment['transactionUsd'] ?? ''}',
        }.withoutNulls,
      );
    } catch (error) {
      if (!mounted) return;
      showTopNotice(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
        type: TopNoticeType.caution,
      );
    } finally {
      if (mounted) safeSetState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final amount = _formatAmount(_amountController.text);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _blue),
          onPressed: () => context.goNamed(GiftWidget.routeName),
        ),
        title: Text(
          'Create Gift',
          style: theme.titleMedium.override(
            color: theme.primaryText,
            fontSize: 18,
            letterSpacing: 0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 18, 28),
          children: [
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gift amount',
                    style: theme.titleMedium.override(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    amount,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fund with $_crypto, then share the issued gift code.',
                    style: theme.bodySmall.override(
                      color: Colors.white.withValues(alpha: .84),
                      fontSize: 11.5,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...[
              Row(
                children: [
                  _amountCard('2000'),
                  const SizedBox(width: 8),
                  _amountCard('5000'),
                  const SizedBox(width: 8),
                  _amountCard('10000'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _amountCard('20000'),
                  const SizedBox(width: 8),
                  _amountCard('50000'),
                  const SizedBox(width: 8),
                  _amountCard('100000'),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Custom amount'),
                style: GoogleFonts.inter(
                  color: theme.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                onChanged: (_) => safeSetState(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _payWith,
                decoration: _inputDecoration('Pay with'),
                style: theme.bodySmall.override(
                  color: theme.primaryText,
                  fontSize: 12.2,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal,
                ),
                items: const ['Crypto', 'Other options']
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: (value) =>
                    safeSetState(() => _payWith = value ?? _payWith),
              ),
              const SizedBox(height: 12),
              if (_payWith == 'Crypto') ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _crypto,
                        decoration: _inputDecoration('Crypto'),
                        style: GoogleFonts.inter(
                          color: theme.primaryText,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w600,
                        ),
                        items: const ['USDT', 'BTC', 'ETH', 'BNB', 'TRX']
                            .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ))
                            .toList(),
                        onChanged: (value) => safeSetState(() {
                          _crypto = value ?? _crypto;
                          if (_crypto != 'USDT') _network = _selectedNetwork;
                        }),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _crypto == 'USDT'
                          ? DropdownButtonFormField<String>(
                              initialValue: _network,
                              decoration: _inputDecoration('Network'),
                              style: GoogleFonts.inter(
                                color: theme.primaryText,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                              ),
                              items: const ['TRC20', 'ERC20', 'BEP20']
                                  .map((item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item),
                                      ))
                                  .toList(),
                              onChanged: (value) => safeSetState(
                                  () => _network = value ?? _network),
                            )
                          : Container(
                              height: 48,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  12, 0, 10, 0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: _blue.withValues(alpha: .16)),
                              ),
                              child: Text(
                                _selectedNetwork,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall.override(
                                  color: theme.primaryText,
                                  fontSize: 11.6,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _payWith == 'Crypto'
                  ? _cryptoFundingCard()
                  : Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(13, 12, 13, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _blue.withValues(alpha: .12)),
                      ),
                      child: Text(
                        'Other payment options will be configured soon.',
                        style: theme.bodySmall.override(
                          color: theme.secondaryText,
                          fontSize: 11,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: StatusActionButton(
                  text: 'Continue',
                  isLoading: _creating,
                  isDone: false,
                  idleIcon: Icons.arrow_forward_rounded,
                  onPressed: _continueToFunding,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
