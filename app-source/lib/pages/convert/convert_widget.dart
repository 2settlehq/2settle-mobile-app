import '/components/settle_numeric_keypad.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'convert_model.dart';
export 'convert_model.dart';

class ConvertWidget extends StatefulWidget {
  const ConvertWidget({super.key});

  static String routeName = 'Convert';
  static String routePath = 'convert';

  @override
  State<ConvertWidget> createState() => _ConvertWidgetState();
}

class _ConvertWidgetState extends State<ConvertWidget>
    with SingleTickerProviderStateMixin {
  late ConvertModel _model;
  late TextEditingController _amountController;
  late TextEditingController _receiveController;
  late AnimationController _cursorController;
  late Animation<double> _cursorOpacity;
  static const _blue = Color(0xFF4472C4);
  static const _rateUrl = 'https://api.2settle.io/v1/rate';
  static const _cryptoPriceUrl =
      'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,binancecoin,tron,tether&vs_currencies=usd';
  static const _selectorWidth = 176.0;
  static const _selectorHeight = 38.0;
  static const _selectorNotchWidth = 196.0;
  static const _selectorNotchDepth = 48.0;

  bool _fromCrypto = true;
  bool _editingReceive = false;
  bool _receiveInputActive = false;
  String _crypto = 'USDT';
  String _fiat = 'NGN';
  double _usdtNgnRate = 1540.00;
  bool _loadingRate = true;
  Map<String, double> _cryptoUsdPrices = {
    'BTC': 65000.0,
    'ETH': 3200.0,
    'BNB': 580.0,
    'TRX': 0.12,
    'USDT': 1.0,
  };

  static const _cryptoOptions = ['BTC', 'ETH', 'BNB', 'TRX', 'USDT'];
  static const _fiatOptions = ['NGN', 'USD'];
  static const _priceIds = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'BNB': 'binancecoin',
    'TRX': 'tron',
    'USDT': 'tether',
  };

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ConvertModel());
    _amountController = TextEditingController(text: '10');
    _receiveController = TextEditingController();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _cursorOpacity = Tween<double>(begin: 0.18, end: 1.0).animate(
      CurvedAnimation(parent: _cursorController, curve: Curves.easeInOut),
    );
    _loadRate();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receiveController.dispose();
    _cursorController.dispose();
    _model.dispose();
    super.dispose();
  }

  double get _amount =>
      double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0;
  double get _receiveInput =>
      double.tryParse(_receiveController.text.replaceAll(',', '').trim()) ?? 0;

  String get _fromAsset => _fromCrypto ? _crypto : _fiat;
  String get _toAsset => _fromCrypto ? _fiat : _crypto;
  double get _cryptoUsdPrice => _cryptoUsdPrices[_crypto] ?? 1.0;
  double get _cryptoFiatPrice =>
      _fiat == 'NGN' ? _cryptoUsdPrice * _usdtNgnRate : _cryptoUsdPrice;

  double get _received {
    if (_editingReceive) return _receiveInput;
    if (_amount <= 0) return 0;
    if (_fromCrypto) {
      return _amount * _cryptoFiatPrice;
    }
    return _amount / _cryptoFiatPrice;
  }

  double get _requiredFromAmount {
    if (!_editingReceive) return _amount;
    if (_receiveInput <= 0 || _cryptoFiatPrice <= 0) return 0;
    if (_fromCrypto) {
      return _receiveInput / _cryptoFiatPrice;
    }
    return _receiveInput * _cryptoFiatPrice;
  }

  String get _rateText => _fiat == 'NGN'
      ? '1 $_crypto = ₦${_formatFiat(_cryptoFiatPrice)}'
      : '1 $_crypto = \$${_formatFiat(_cryptoUsdPrice)}';

  Future<void> _loadRate() async {
    await Future.wait([
      _loadNgnRate(),
      _loadCryptoPrices(),
    ]);
    if (!mounted) return;
    safeSetState(() => _loadingRate = false);
  }

  Future<void> _loadNgnRate() async {
    try {
      final response = await http.get(Uri.parse(_rateUrl), headers: const {
        'accept': 'application/json'
      }).timeout(const Duration(seconds: 6));
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final parsed = _parseRatePayload(jsonDecode(response.body));
      if (parsed == null || !mounted) return;
      safeSetState(() => _usdtNgnRate = parsed);
    } catch (_) {
      // Keep the fallback NGN rate.
    }
  }

  Future<void> _loadCryptoPrices() async {
    try {
      final response = await http.get(Uri.parse(_cryptoPriceUrl),
          headers: const {
            'accept': 'application/json'
          }).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      final payload = jsonDecode(response.body);
      if (payload is! Map) return;

      final prices = Map<String, double>.from(_cryptoUsdPrices);
      for (final entry in _priceIds.entries) {
        final rawPrice = payload[entry.value];
        if (rawPrice is Map) {
          final usd = rawPrice['usd'];
          if (usd is num && usd.isFinite) {
            prices[entry.key] = usd.toDouble();
          }
        }
      }
      if (!mounted) return;
      safeSetState(() => _cryptoUsdPrices = prices);
    } catch (_) {
      // Keep fallback crypto prices if the pricing endpoint is unavailable.
    }
  }

  double? _parseRatePayload(dynamic payload) {
    if (payload is num && payload.isFinite) return payload.toDouble();
    if (payload is String) {
      final parsed = double.tryParse(payload.replaceAll(',', '').trim());
      if (parsed != null && parsed.isFinite) return parsed;
    }
    if (payload is List) {
      for (final item in payload) {
        final parsed = _parseRatePayload(item);
        if (parsed != null) return parsed;
      }
    }
    if (payload is Map) {
      const keys = [
        'rate',
        'price',
        'value',
        'ngn',
        'usdt_ngn',
        'USDT_NGN',
        'buy',
        'sell',
      ];
      for (final key in keys) {
        if (payload.containsKey(key)) {
          final parsed = _parseRatePayload(payload[key]);
          if (parsed != null) return parsed;
        }
      }
      for (final value in payload.values) {
        final parsed = _parseRatePayload(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  void _swap() {
    safeSetState(() {
      _fromCrypto = !_fromCrypto;
      _editingReceive = false;
      _receiveController.clear();
    });
  }

  void _openAmountKeypad() {
    safeSetState(() => _receiveInputActive = false);
    SettleNumericKeypad.show(
      context,
      title: 'Enter amount',
      initialValue: _amountController.text,
      allowDecimal: true,
      showPreview: false,
      onChanged: (value) {
        _amountController.text = value;
        _editingReceive = false;
        _receiveInputActive = false;
        safeSetState(() {});
      },
      onDone: (value) {
        _amountController.text = value;
        _editingReceive = false;
        _receiveInputActive = false;
        safeSetState(() {});
      },
    );
  }

  void _openReceiveKeypad() {
    safeSetState(() => _receiveInputActive = true);
    SettleNumericKeypad.show(
      context,
      title: 'Enter receive amount',
      initialValue: _receiveController.text,
      allowDecimal: true,
      onChanged: (value) {
        _receiveController.text = value;
        _editingReceive = true;
        _receiveInputActive = true;
        safeSetState(() {});
      },
      onDone: (value) {
        _receiveController.text = value;
        _editingReceive = true;
        _receiveInputActive = true;
        safeSetState(() {});
      },
    );
  }

  String _roundDownCrypto(double value) =>
      ((value * 100000).floor() / 100000).toStringAsFixed(5);

  String _formatFiat(double value) =>
      NumberFormat('#,##0.00', 'en_US').format(value);

  String _displayAmount(double value, String asset) {
    if (asset == 'NGN') return '₦${_formatFiat(value)}';
    if (asset == 'USD') return '\$${_formatFiat(value)}';
    return '${_roundDownCrypto(value)} $asset';
  }

  String _plainAmount(double value, String asset) {
    if (asset == 'NGN' || asset == 'USD') return _formatFiat(value);
    return _roundDownCrypto(value);
  }

  String _assetName(String asset) {
    switch (asset) {
      case 'BTC':
        return 'Bitcoin';
      case 'ETH':
        return 'Ethereum';
      case 'BNB':
        return 'BNB';
      case 'TRX':
        return 'TRON';
      case 'USDT':
        return 'Tether';
      case 'NGN':
        return 'Naira';
      case 'USD':
        return 'Dollar';
      default:
        return asset;
    }
  }

  Widget _assetDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool onDark = false,
  }) {
    return Container(
      width: _selectorWidth,
      height: _selectorHeight,
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 9.0, 0.0),
      decoration: BoxDecoration(
        color: onDark ? Colors.white : _blue,
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(
          color: onDark ? Colors.white : _blue,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12.0,
            color: Color(0x1E000000),
            offset: Offset(0.0, 5.0),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14.0),
          isExpanded: true,
          selectedItemBuilder: (context) => options
              .map(
                (option) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option,
                      style: GoogleFonts.inter(
                        color: onDark ? _blue : Colors.white,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Flexible(
                      child: Text(
                        _assetName(option),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: onDark
                              ? const Color(0xFF8B97A2)
                              : Colors.white.withValues(alpha: 0.78),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: onDark ? _blue : Colors.white,
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option,
                        style: GoogleFonts.inter(
                          color: _blue,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        _assetName(option),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8B97A2),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _assetIcon(String asset, {bool dark = false}) {
    return Container(
      width: 34.0,
      height: 34.0,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.16)
            : _blue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        asset == 'NGN' || asset == 'USD'
            ? Icons.account_balance_rounded
            : asset == 'BTC'
                ? Icons.currency_bitcoin_rounded
                : Icons.token_rounded,
        color: dark ? Colors.white : _blue,
        size: 18.0,
      ),
    );
  }

  Widget _inputPanel() {
    final asset = _fromAsset;
    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          PhysicalShape(
            color: _blue,
            elevation: 10.0,
            shadowColor: const Color(0x33000000),
            clipper: const _TopSelectorNotchClipper(
              radius: 22.0,
              notchWidth: _selectorNotchWidth,
              notchDepth: _selectorNotchDepth,
              notchRadius: 24.0,
            ),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 52.0, 16.0, 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _openAmountKeypad,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, 2.0, 0.0, 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _amountController.text.trim().isEmpty
                                  ? _plainAmount(_requiredFromAmount, asset)
                                  : _editingReceive
                                      ? _plainAmount(_requiredFromAmount, asset)
                                      : _amountController.text.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: _amountController.text.trim().isEmpty
                                    ? Colors.white.withValues(alpha: 0.42)
                                    : Colors.white,
                                fontSize: 32.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3.0),
                          FadeTransition(
                            opacity: _receiveInputActive
                                ? const AlwaysStoppedAnimation<double>(0.0)
                                : _cursorOpacity,
                            child: Container(
                              width: 2.0,
                              height: 31.0,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'You convert',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4.0,
            child: _assetDropdown(
              value: asset,
              options: _fromCrypto ? _cryptoOptions : _fiatOptions,
              onDark: true,
              onChanged: (value) {
                if (value == null) return;
                safeSetState(() {
                  if (_fromCrypto) {
                    _crypto = value;
                  } else {
                    _fiat = value;
                  }
                  _editingReceive = false;
                  _receiveInputActive = false;
                  _receiveController.clear();
                });
              },
            ),
          ),
          Positioned(
            top: 8.0,
            right: 16.0,
            child: _assetIcon(asset, dark: true),
          ),
        ],
      ),
    );
  }

  Widget _outputPanel() {
    final theme = FlutterFlowTheme.of(context);
    final asset = _toAsset;
    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          PhysicalShape(
            color: Colors.white,
            elevation: 7.0,
            shadowColor: const Color(0x22000000),
            clipper: const _BottomSelectorNotchClipper(
              radius: 22.0,
              notchWidth: _selectorNotchWidth,
              notchDepth: _selectorNotchDepth,
              notchRadius: 24.0,
            ),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 53.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You receive',
                    style: theme.bodySmall.override(
                      font: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontStyle: theme.bodySmall.fontStyle,
                      ),
                      color: theme.secondaryText,
                      fontSize: 11.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.normal,
                      fontStyle: theme.bodySmall.fontStyle,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  InkWell(
                    onTap: _openReceiveKeypad,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _editingReceive &&
                                    _receiveController.text.trim().isNotEmpty
                                ? _displayAmount(_receiveInput, asset)
                                : _displayAmount(_received, asset),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: _blue,
                              fontSize: 30.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        FadeTransition(
                          opacity: _receiveInputActive
                              ? _cursorOpacity
                              : const AlwaysStoppedAnimation<double>(0.0),
                          child: Container(
                            width: 2.0,
                            height: 28.0,
                            decoration: BoxDecoration(
                              color: _blue.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16.0,
            right: 16.0,
            child: _assetIcon(asset),
          ),
          Positioned(
            bottom: 4.0,
            child: _assetDropdown(
              value: asset,
              options: _fromCrypto ? _fiatOptions : _cryptoOptions,
              onChanged: (value) {
                if (value == null) return;
                safeSetState(() {
                  if (_fromCrypto) {
                    _fiat = value;
                  } else {
                    _crypto = value;
                  }
                  _editingReceive = false;
                  _receiveInputActive = false;
                  _receiveController.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.bodySmall.override(
              font: TextStyle(
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodySmall.fontStyle,
              ),
              color: theme.secondaryText,
              letterSpacing: 0.0,
              fontWeight: FontWeight.normal,
              fontStyle: theme.bodySmall.fontStyle,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: theme.primaryText,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0.0,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          buttonSize: 52.0,
          icon: const Icon(Icons.arrow_back_rounded, color: _blue, size: 24.0),
          onPressed: context.safePop,
        ),
        title: Text(
          'Convert',
          style: theme.titleSmall.override(
            font: TextStyle(
              fontWeight: FontWeight.w700,
              fontStyle: theme.titleSmall.fontStyle,
            ),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w700,
            fontStyle: theme.titleSmall.fontStyle,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(18.0, 14.0, 18.0, 28.0),
          children: [
            Text(
              'Live conversion',
              style: theme.titleMedium.override(
                font: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontStyle: theme.titleMedium.fontStyle,
                ),
                color: _blue,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w700,
                fontStyle: theme.titleMedium.fontStyle,
              ),
            ),
            const SizedBox(height: 5.0),
            Text(
              'Convert BTC, ETH, BNB, TRX, and USDT against naira or dollar in real time.',
              style: theme.bodySmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
                color: theme.secondaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodySmall.fontStyle,
              ),
            ),
            const SizedBox(height: 14.0),
            Text(
              _loadingRate ? 'Updating prices...' : _rateText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF303844),
                fontSize: 18.0,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(
                    blurRadius: 8.0,
                    color: Color(0x18000000),
                    offset: Offset(0.0, 2.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    _inputPanel(),
                    const SizedBox(height: 3.0),
                    _outputPanel(),
                  ],
                ),
                InkWell(
                  onTap: _swap,
                  borderRadius: BorderRadius.circular(999.0),
                  child: Container(
                    width: 50.0,
                    height: 50.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _blue, width: 3.0),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12.0,
                          color: Color(0x22000000),
                          offset: Offset(0.0, 5.0),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.swap_vert_rounded,
                      color: _blue,
                      size: 28.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18.0),
            Center(
              child: Text(
                'Live ${_assetName(_crypto)} conversion',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6D7884),
                  fontSize: 11.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 3.0, 16.0, 3.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                children: [
                  _metric('Route', '$_fromAsset > $_toAsset'),
                  const Divider(height: 1.0),
                  _metric('USD price', '\$${_formatFiat(_cryptoUsdPrice)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSelectorNotchClipper extends CustomClipper<Path> {
  const _TopSelectorNotchClipper({
    required this.radius,
    required this.notchWidth,
    required this.notchDepth,
    required this.notchRadius,
  });

  final double radius;
  final double notchWidth;
  final double notchDepth;
  final double notchRadius;

  @override
  Path getClip(Size size) {
    final notchLeft = (size.width - notchWidth) / 2;
    final notchRight = notchLeft + notchWidth;
    final notchBottom = notchDepth;
    final corner = radius;
    final curve = notchRadius;

    return Path()
      ..moveTo(corner, 0)
      ..lineTo(notchLeft - curve, 0)
      ..quadraticBezierTo(notchLeft, 0, notchLeft, curve)
      ..lineTo(notchLeft, notchBottom - curve)
      ..quadraticBezierTo(
          notchLeft, notchBottom, notchLeft + curve, notchBottom)
      ..lineTo(notchRight - curve, notchBottom)
      ..quadraticBezierTo(
        notchRight,
        notchBottom,
        notchRight,
        notchBottom - curve,
      )
      ..lineTo(notchRight, curve)
      ..quadraticBezierTo(notchRight, 0, notchRight + curve, 0)
      ..lineTo(size.width - corner, 0)
      ..quadraticBezierTo(size.width, 0, size.width, corner)
      ..lineTo(size.width, size.height - corner)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - corner,
        size.height,
      )
      ..lineTo(corner, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - corner)
      ..lineTo(0, corner)
      ..quadraticBezierTo(0, 0, corner, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant _TopSelectorNotchClipper oldClipper) {
    return radius != oldClipper.radius ||
        notchWidth != oldClipper.notchWidth ||
        notchDepth != oldClipper.notchDepth ||
        notchRadius != oldClipper.notchRadius;
  }
}

class _BottomSelectorNotchClipper extends CustomClipper<Path> {
  const _BottomSelectorNotchClipper({
    required this.radius,
    required this.notchWidth,
    required this.notchDepth,
    required this.notchRadius,
  });

  final double radius;
  final double notchWidth;
  final double notchDepth;
  final double notchRadius;

  @override
  Path getClip(Size size) {
    final notchLeft = (size.width - notchWidth) / 2;
    final notchRight = notchLeft + notchWidth;
    final notchTop = size.height - notchDepth;
    final corner = radius;
    final curve = notchRadius;

    return Path()
      ..moveTo(corner, 0)
      ..lineTo(size.width - corner, 0)
      ..quadraticBezierTo(size.width, 0, size.width, corner)
      ..lineTo(size.width, size.height - corner)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - corner,
        size.height,
      )
      ..lineTo(notchRight + curve, size.height)
      ..quadraticBezierTo(
          notchRight, size.height, notchRight, size.height - curve)
      ..lineTo(notchRight, notchTop + curve)
      ..quadraticBezierTo(notchRight, notchTop, notchRight - curve, notchTop)
      ..lineTo(notchLeft + curve, notchTop)
      ..quadraticBezierTo(notchLeft, notchTop, notchLeft, notchTop + curve)
      ..lineTo(notchLeft, size.height - curve)
      ..quadraticBezierTo(
          notchLeft, size.height, notchLeft - curve, size.height)
      ..lineTo(corner, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - corner)
      ..lineTo(0, corner)
      ..quadraticBezierTo(0, 0, corner, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant _BottomSelectorNotchClipper oldClipper) {
    return radius != oldClipper.radius ||
        notchWidth != oldClipper.notchWidth ||
        notchDepth != oldClipper.notchDepth ||
        notchRadius != oldClipper.notchRadius;
  }
}
