import '/components/status_action_button.dart';
import '/components/top_notice.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiveCryptoWalletWidget extends StatefulWidget {
  const ReceiveCryptoWalletWidget({super.key});

  static String routeName = 'ReceiveCryptoWallet';
  static String routePath = 'receiveCryptoWallet';

  @override
  State<ReceiveCryptoWalletWidget> createState() =>
      _ReceiveCryptoWalletWidgetState();
}

class _ReceiveCryptoWalletWidgetState extends State<ReceiveCryptoWalletWidget> {
  static const _blue = Color(0xFF4472C4);
  static const _green = Color(0xFF25A55F);
  static const _storageKey = ReceivePaymentDetailsWidget.storageKey;

  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final List<String> _networks = const [
    'EVM',
    'BTC',
    'TRON',
  ];
  List<_WalletDestination> _wallets = [];
  String _network = 'EVM';
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null || stored.isEmpty) return;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map || decoded['wallets'] is! List) return;
      final wallets = (decoded['wallets'] as List)
          .whereType<Map>()
          .map((item) => _WalletDestination.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
      if (!mounted) return;
      safeSetState(() {
        _wallets = wallets;
        if (_wallets.isNotEmpty && !_wallets.any((item) => item.isDefault)) {
          _wallets.first.isDefault = true;
        }
      });
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> payload = {
      'nairaAccounts': [],
      'dollarAccounts': [],
      'wallets': [],
    };
    final stored = prefs.getString(_storageKey);
    if (stored != null && stored.isNotEmpty) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    payload['wallets'] = _wallets.map((item) => item.toJson()).toList();
    payload['updatedAt'] = DateTime.now().toIso8601String();
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  Future<void> _saveWallet() async {
    final address = _addressController.text.trim();
    final label = _labelController.text.trim().isEmpty
        ? '$_network wallet'
        : _labelController.text.trim();
    if (address.isEmpty) {
      showTopNotice(
        context,
        message: 'Enter a wallet address.',
        type: TopNoticeType.caution,
      );
      return;
    }
    safeSetState(() {
      _isSaving = true;
      _isSaved = false;
    });
    await Future.delayed(const Duration(milliseconds: 360));
    if (!mounted) return;
    safeSetState(() {
      _wallets.add(
        _WalletDestination(
          id: 'WAL-${DateTime.now().millisecondsSinceEpoch}',
          title: label,
          primary: address,
          secondary: _network,
          name: label,
          network: _network,
          isDefault: _wallets.isEmpty,
        ),
      );
      _labelController.clear();
      _addressController.clear();
      _isSaving = false;
      _isSaved = true;
    });
    await _persist();
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) safeSetState(() => _isSaved = false);
    });
  }

  void _makeDefault(_WalletDestination item) {
    safeSetState(() {
      for (final wallet in _wallets) {
        wallet.isDefault = wallet == item;
      }
    });
    _persist();
  }

  void _delete(_WalletDestination item) {
    safeSetState(() {
      _wallets.remove(item);
      if (_wallets.isNotEmpty && !_wallets.any((entry) => entry.isDefault)) {
        _wallets.first.isDefault = true;
      }
    });
    _persist();
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsetsDirectional.fromSTEB(14.0, 13.0, 14.0, 13.0),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _blue.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _blue),
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
  }

  String get _networkHint {
    if (_network == 'EVM') return 'ETH, BNB, USDT ERC20, USDT BEP20';
    if (_network == 'TRON') return 'TRX and USDT TRC20';
    return 'BTC only';
  }

  Widget _walletTile(_WalletDestination item) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 8.0),
      padding: const EdgeInsetsDirectional.fromSTEB(11.0, 8.0, 8.0, 8.0),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _blue.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            item.isDefault ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: item.isDefault ? _green : theme.secondaryText,
            size: 20.0,
          ),
          const SizedBox(width: 9.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.override(
                    color: theme.primaryText,
                    fontSize: 11.8,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  '${item.secondary} • ${item.primary}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: theme.secondaryText,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: _blue, size: 20.0),
            onSelected: (value) {
              if (value == 'default') _makeDefault(item);
              if (value == 'delete') _delete(item);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'default', child: Text('Make default')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
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
        backgroundColor: _blue,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          buttonSize: 48.0,
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 24.0),
          onPressed: () =>
              context.goNamed(ReceivePaymentDetailsWidget.routeName),
        ),
        title: Text(
          'Wallet Addresses',
          style: theme.headlineMedium.override(
            color: Colors.white,
            fontSize: 20.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(18.0, 18.0, 18.0, 26.0),
          children: [
            Text(
              'Save wallet addresses',
              style: theme.bodyMedium.override(
                color: _blue,
                fontSize: 15.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12.0),
            DropdownButtonFormField<String>(
              initialValue: _network,
              decoration: _inputDecoration('Wallet network'),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _blue),
              items: _networks
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) {
                if (value != null) safeSetState(() => _network = value);
              },
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              controller: _addressController,
              decoration:
                  _inputDecoration('Wallet address', hint: _networkHint),
              style: GoogleFonts.inter(
                color: theme.primaryText,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              controller: _labelController,
              decoration: _inputDecoration('Save as'),
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 12.0),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: StatusActionButton(
                text: 'Save it',
                isLoading: _isSaving,
                isDone: _isSaved,
                idleIcon: Icons.save_rounded,
                height: 46.0,
                horizontalPadding: 18.0,
                trailingPadding: 5.0,
                iconBoxSize: 36.0,
                iconSize: 19.0,
                fontSize: 13.5,
                gap: 9.0,
                backgroundColor: _blue,
                textColor: Colors.white,
                iconBackgroundColor: Colors.white,
                iconColor: _blue,
                onPressed: _saveWallet,
              ),
            ),
            const SizedBox(height: 18.0),
            Text(
              'Saved wallets',
              style: theme.bodyMedium.override(
                color: _blue,
                fontSize: 15.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8.0),
            if (_wallets.isEmpty)
              Text(
                'Saved wallet addresses will appear here.',
                style: theme.bodySmall.override(
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              ..._wallets.map(_walletTile),
          ],
        ),
      ),
    );
  }
}

class _WalletDestination {
  _WalletDestination({
    required this.id,
    required this.title,
    required this.primary,
    required this.secondary,
    required this.name,
    required this.network,
    required this.isDefault,
  });

  final String id;
  final String title;
  final String primary;
  final String secondary;
  final String name;
  final String network;
  bool isDefault;

  factory _WalletDestination.fromJson(Map<String, dynamic> json) {
    return _WalletDestination(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Wallet address',
      primary: json['primary']?.toString() ?? '',
      secondary: json['secondary']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      network: json['network']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'primary': primary,
        'secondary': secondary,
        'name': name,
        'network': network,
        'isDefault': isDefault,
      };
}
