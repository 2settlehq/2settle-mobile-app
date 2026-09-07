import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_cards_model.dart';
export 'my_cards_model.dart';

const double _cardCutoutWidth = 132.0;
const double _cardCutoutHeight = 52.0;
const double _cardCutoutCurve = 28.0;
const double _addCardButtonWidth = 122.0;
const double _addCardButtonHeight = 44.0;
const double _addCardButtonRightInset = 3.0;
const double _addCardButtonBottomInset = 3.0;

class MyCardsWidget extends StatefulWidget {
  const MyCardsWidget({super.key});

  static String routeName = 'My_Cards';
  static String routePath = 'myCards';

  @override
  State<MyCardsWidget> createState() => _MyCardsWidgetState();
}

class _MyCardsWidgetState extends State<MyCardsWidget> {
  late MyCardsModel _model;
  static const _blue = Color(0xFF4472C4);
  int _selectedCardIndex = 2;
  String _displayName = 'Kayode';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MyCardsModel());
    _loadProfileName();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _openCardDetail() {
    context.pushNamed(CardDetailsWidget.routeName);
  }

  Future<void> _loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('2settle_profile_name')?.trim();
    if (!mounted || stored == null || stored.isEmpty) return;
    safeSetState(() => _displayName = stored.split(RegExp(r'\s+')).first);
  }

  List<Map<String, Object>> get _cards => const [
        {
          'color': _blue,
          'brand': 'Add new card',
          'suffix': '',
          'holder': '',
          'expiry': '',
        },
        {
          'color': Colors.white,
          'brand': '2Settle',
          'suffix': '472',
          'holder': 'Kayode',
          'expiry': '01/28',
        },
        {
          'color': _blue,
          'brand': 'VISA',
          'suffix': '9743',
          'holder': 'Kayode Adewale',
          'expiry': '02/28',
        },
        {
          'color': Colors.white,
          'brand': 'MASTERCARD',
          'suffix': '225',
          'holder': 'Kayode Adewale',
          'expiry': '04/29',
        },
      ];

  void _moveStack(int direction) {
    final next = (_selectedCardIndex + direction) % _cards.length;
    if (next == _selectedCardIndex) return;
    safeSetState(() => _selectedCardIndex = next);
  }

  int _relativeCardOffset(int index) {
    return (index - _selectedCardIndex + _cards.length) % _cards.length;
  }

  Widget _walletCardStack() {
    const cardHeight = 168.0;
    const stackHeight = 246.0;
    const activeTop = 70.0;
    const peekGap = 18.0;
    final orderedIndexes = List<int>.generate(_cards.length, (index) => index)
      ..sort(
        (a, b) => _relativeCardOffset(b).compareTo(_relativeCardOffset(a)),
      );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0.0;
        if (velocity.abs() > 60) {
          _moveStack(1);
        }
      },
      child: SizedBox(
        height: stackHeight,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: orderedIndexes.map((index) {
            final card = _cards[index];
            final offset = _relativeCardOffset(index);
            final active = offset == 0;
            final top = active ? activeTop : activeTop - (offset * peekGap);
            final scale = active
                ? 1.0
                : (1.0 - (offset * 0.026)).clamp(0.9, 0.98).toDouble();
            final sideInset = active ? 0.0 : 7.0 + (offset * 4.0);

            return AnimatedPositioned(
              key: ValueKey(card['suffix']),
              duration: const Duration(milliseconds: 460),
              curve: Curves.easeOutCubic,
              top: top,
              left: sideInset,
              right: sideInset,
              child: IgnorePointer(
                ignoring: false,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: cardHeight,
                    child: _stackedCard(
                      color: card['color']! as Color,
                      brand: card['brand']! as String,
                      suffix: card['suffix']! as String,
                      holder: card['holder']! as String,
                      expiry: card['expiry']! as String,
                      index: index,
                      selected: active,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _stackedCard({
    required Color color,
    required String brand,
    required String suffix,
    required String holder,
    required String expiry,
    required int index,
    required bool selected,
  }) {
    final isWhiteCard = color == Colors.white;
    final textColor = isWhiteCard ? _blue : Colors.white;
    final labelColor = isWhiteCard
        ? _blue.withValues(alpha: 0.62)
        : Colors.white.withValues(alpha: 0.66);

    return InkWell(
      onTap: () {
        if (selected) {
          _openCardDetail();
          return;
        }
        safeSetState(() => _selectedCardIndex = index);
      },
      borderRadius: BorderRadius.circular(22.0),
      child: Stack(
        children: [
          PhysicalShape(
            clipper: selected
                ? const _CardNotchClipper()
                : const ShapeBorderClipper(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24.0)),
                    ),
                  ),
            color: color,
            elevation: 10.0,
            shadowColor: const Color(0x36000000),
            child: Container(
              width: double.infinity,
              height: 168.0,
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 16.0, 18.0, 16.0),
              child: _cardContent(
                brand: brand,
                suffix: suffix,
                holder: holder,
                expiry: expiry,
                textColor: textColor,
                labelColor: labelColor,
                isWhiteCard: isWhiteCard,
                selected: selected,
              ),
            ),
          ),
          if (selected)
            Positioned.fill(
              child: ClipPath(
                clipper: const _CardNotchGapClipper(),
                child: Container(color: const Color(0xFFF4F6FA)),
              ),
            ),
          if (selected)
            Positioned(
              right: _addCardButtonRightInset,
              bottom: _addCardButtonBottomInset,
              child: _addCardCutoutButton(),
            ),
        ],
      ),
    );
  }

  Widget _cardContent({
    required String brand,
    required String suffix,
    required String holder,
    required String expiry,
    required Color textColor,
    required Color labelColor,
    required bool isWhiteCard,
    required bool selected,
  }) {
    return Stack(
      children: [
        Positioned(
          right: -18.0,
          bottom: -35.0,
          child: Opacity(
            opacity: 0.1,
            child: Image.asset(
              'assets/images/a_avatar.png',
              width: 145.0,
              height: 145.0,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              brand,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 18.0,
                fontWeight: FontWeight.w900,
                fontStyle:
                    brand == 'VISA' ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsetsDirectional.only(
                end: selected ? _cardCutoutWidth + 6.0 : 0.0,
              ),
              child: Row(
                children: [
                  _cardMeta(
                    'Exp Date',
                    expiry.isEmpty ? '--/--' : expiry,
                    textColor,
                    labelColor,
                  ),
                  const SizedBox(width: 18.0),
                  _cardMeta('CVV', suffix.isEmpty ? '---' : '***', textColor,
                      labelColor),
                ],
              ),
            ),
            const SizedBox(height: 4.0),
            Padding(
              padding: EdgeInsetsDirectional.only(
                end: selected ? _cardCutoutWidth - 10.0 : 0.0,
              ),
              child: Text(
                suffix.isEmpty ? 'Tap to create card' : '***  ***  ***$suffix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: suffix.isEmpty ? 15.0 : (selected ? 19.0 : 22.0),
                  fontWeight: FontWeight.w900,
                  letterSpacing: suffix.isEmpty ? 0.0 : 1.2,
                ),
              ),
            ),
            const SizedBox(height: 7.0),
            Padding(
              padding: EdgeInsetsDirectional.only(
                end: selected ? _cardCutoutWidth + 10.0 : 0.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _cardMeta(
                    'Holder',
                    holder.isEmpty ? '2Settle' : holder,
                    textColor,
                    labelColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 0.0,
          right: 0.0,
          child: Container(
            width: 44.0,
            height: 24.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isWhiteCard
                  ? _blue.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(100.0),
            ),
            child: Text(
              '•••',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14.0,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addCardCutoutButton() {
    return Container(
      width: _addCardButtonWidth,
      height: _addCardButtonHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(_addCardButtonHeight / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12.0,
            offset: const Offset(0.0, 6.0),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(6.0, 0.0, 12.0, 0.0),
      child: Row(
        children: [
          Container(
            width: 32.0,
            height: 32.0,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFF101820),
              size: 20.0,
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Add Card',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardMeta(String label, String value, Color color, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: labelColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _action(IconData icon, String label) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: InkWell(
        onTap: _openCardDetail,
        borderRadius: BorderRadius.circular(14.0),
        child: Column(
          children: [
            Container(
              width: 43.0,
              height: 43.0,
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Icon(icon, color: _blue, size: 20.0),
            ),
            const SizedBox(height: 6.0),
            Text(
              label,
              style: theme.bodySmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
                color: theme.primaryText,
                fontSize: 10.2,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodySmall.fontStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transaction({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10.0, 9.0, 10.0, 9.0),
      margin: const EdgeInsetsDirectional.only(bottom: 9.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Row(
        children: [
          Container(
            width: 38.0,
            height: 38.0,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, color: _blue, size: 18.0),
          ),
          const SizedBox(width: 11.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.bodySmall.override(
                    font: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontStyle: theme.bodySmall.fontStyle,
                    ),
                    fontSize: 11.2,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle: theme.bodySmall.fontStyle,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: theme.secondaryText,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              color: theme.primaryText,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
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
          onPressed: () => context.goNamed(AllServicesWidget.routeName),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 14.0),
            child: InkWell(
              onTap: _openCardDetail,
              borderRadius: BorderRadius.circular(18.0),
              child: Container(
                width: 36.0,
                height: 36.0,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: _blue,
                  size: 18.0,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(18.0, 2.0, 18.0, 24.0),
          children: [
            Text(
              'Hi, $_displayName',
              style: theme.bodyMedium.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodyMedium.fontStyle,
                ),
                color: theme.primaryText,
                fontSize: 13.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodyMedium.fontStyle,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              'Welcome Back!',
              style: theme.titleMedium.override(
                font: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontStyle: theme.titleMedium.fontStyle,
                ),
                color: theme.primaryText,
                fontSize: 22.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w800,
                fontStyle: theme.titleMedium.fontStyle,
              ),
            ),
            const SizedBox(height: 16.0),
            _walletCardStack(),
            const SizedBox(height: 10.0),
            Row(
              children: [
                _action(Icons.savings_rounded, 'Deposit'),
                _action(Icons.compare_arrows_rounded, 'Transfer'),
                _action(Icons.download_rounded, 'Withdraw'),
                _action(Icons.grid_view_rounded, 'More'),
              ],
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Transactions',
                  style: theme.titleSmall.override(
                    font: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontStyle: theme.titleSmall.fontStyle,
                    ),
                    color: theme.primaryText,
                    fontSize: 18.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w800,
                    fontStyle: theme.titleSmall.fontStyle,
                  ),
                ),
                Text(
                  'Today',
                  style: GoogleFonts.inter(
                    color: theme.secondaryText,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            _transaction(
              icon: Icons.near_me_rounded,
              title: '2Settle payout',
              subtitle: 'Sent',
              amount: '- ₦12,664',
            ),
            _transaction(
              icon: Icons.swap_horiz_rounded,
              title: 'Crypto convert',
              subtitle: 'Exchange',
              amount: '- 3.00 USDT',
            ),
            _transaction(
              icon: Icons.credit_card_rounded,
              title: 'Virtual card',
              subtitle: 'Funding',
              amount: '+ ₦8,400',
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNotchClipper extends CustomClipper<Path> {
  const _CardNotchClipper();

  @override
  Path getClip(Size size) {
    const outerRadius = 24.0;
    const rightEntryRadius = 18.0;
    const bottomReturnRadius = 28.0;
    final w = size.width;
    final h = size.height;
    final notchLeft = w - _cardCutoutWidth;
    final notchTop = h - _cardCutoutHeight;
    final notchEntryY = notchTop - rightEntryRadius;
    final bottomReturnX = notchLeft - bottomReturnRadius;
    final bottomReturnY = h - bottomReturnRadius;

    return Path()
      ..moveTo(outerRadius, 0)
      ..lineTo(w - outerRadius, 0)
      ..quadraticBezierTo(w, 0, w, outerRadius)
      ..lineTo(w, notchEntryY)
      ..quadraticBezierTo(w, notchTop, w - rightEntryRadius, notchTop)
      ..lineTo(notchLeft + _cardCutoutCurve, notchTop)
      ..cubicTo(
        notchLeft + (_cardCutoutCurve * 0.46),
        notchTop,
        notchLeft,
        notchTop + (_cardCutoutCurve * 0.46),
        notchLeft,
        notchTop + _cardCutoutCurve,
      )
      ..lineTo(notchLeft, bottomReturnY)
      ..quadraticBezierTo(notchLeft, h, bottomReturnX, h)
      ..lineTo(outerRadius, h)
      ..quadraticBezierTo(0, h, 0, h - outerRadius)
      ..lineTo(0, outerRadius)
      ..quadraticBezierTo(0, 0, outerRadius, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CardNotchGapClipper extends CustomClipper<Path> {
  const _CardNotchGapClipper();

  @override
  Path getClip(Size size) {
    const rightEntryRadius = 18.0;
    const bottomReturnRadius = 28.0;
    final w = size.width;
    final h = size.height;
    final notchLeft = w - _cardCutoutWidth;
    final notchTop = h - _cardCutoutHeight;
    final notchEntryY = notchTop - rightEntryRadius;
    final bottomReturnX = notchLeft - bottomReturnRadius;
    final bottomReturnY = h - bottomReturnRadius;

    return Path()
      ..moveTo(w, notchEntryY)
      ..lineTo(w, h)
      ..lineTo(bottomReturnX, h)
      ..quadraticBezierTo(notchLeft, h, notchLeft, bottomReturnY)
      ..lineTo(notchLeft, notchTop + _cardCutoutCurve)
      ..cubicTo(
        notchLeft,
        notchTop + (_cardCutoutCurve * 0.46),
        notchLeft + (_cardCutoutCurve * 0.46),
        notchTop,
        notchLeft + _cardCutoutCurve,
        notchTop,
      )
      ..lineTo(w - rightEntryRadius, notchTop)
      ..quadraticBezierTo(w, notchTop, w, notchEntryY)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
