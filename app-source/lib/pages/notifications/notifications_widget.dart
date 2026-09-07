import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsWidget extends StatefulWidget {
  const NotificationsWidget({super.key});

  static String routeName = 'Notifications';
  static String routePath = 'notifications';
  static const storageKey = '2settle_read_notifications';

  static const defaults = [
    _NotificationData(
      id: 'general_kyc_required',
      tab: _NotificationTab.general,
      title: 'Complete your KYC',
      body:
          'Verify your identity to unlock higher settlement limits, faster withdrawals, and safer account recovery.',
      icon: Icons.verified_user_rounded,
      tone: _NoticeTone.info,
    ),
    _NotificationData(
      id: 'general_thank_you',
      tab: _NotificationTab.general,
      title: 'Thank you for using 2Settle',
      body:
          'We appreciate you choosing 2Settle. Your feedback is helping shape a faster crypto-to-cash experience.',
      icon: Icons.favorite_rounded,
      tone: _NoticeTone.positive,
    ),
    _NotificationData(
      id: 'updates_live_rate',
      tab: _NotificationTab.updates,
      title: 'Live rate is active',
      body:
          'Your dashboard now refreshes USDT/NGN automatically so you can send with clearer market context.',
      icon: Icons.trending_up_rounded,
      tone: _NoticeTone.info,
    ),
    _NotificationData(
      id: 'notice_security',
      tab: _NotificationTab.notice,
      title: 'Security notice',
      body:
          'Never share your passcode or wallet recovery details. 2Settle support will never ask for them.',
      icon: Icons.warning_amber_rounded,
      tone: _NoticeTone.caution,
    ),
  ];

  static Future<int> unreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final read = prefs.getStringList(storageKey) ?? const [];
    return defaults.where((item) => !read.contains(item.id)).length;
  }

  @override
  State<NotificationsWidget> createState() => _NotificationsWidgetState();
}

class _NotificationsWidgetState extends State<NotificationsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<String> _readIds = {};
  _NotificationData? _selected;

  static const _blue = Color(0xFF4472C4);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReadIds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    safeSetState(() {
      _readIds = (prefs.getStringList(NotificationsWidget.storageKey) ??
              const <String>[])
          .toSet();
    });
  }

  Future<void> _markRead(_NotificationData item) async {
    final next = {..._readIds, item.id};
    safeSetState(() {
      _readIds = next;
      _selected = item;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(NotificationsWidget.storageKey, next.toList());
  }

  List<_NotificationData> _itemsFor(_NotificationTab tab) =>
      NotificationsWidget.defaults.where((item) => item.tab == tab).toList();

  int _unreadFor(_NotificationTab tab) {
    return _itemsFor(tab).where((item) => !_readIds.contains(item.id)).length;
  }

  Widget _tabLabel(String label, _NotificationTab tab) {
    final count = _unreadFor(tab);
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 5.0),
            Container(
              constraints: const BoxConstraints(minWidth: 17.0),
              padding: const EdgeInsetsDirectional.fromSTEB(5.0, 2.0, 5.0, 2.0),
              decoration: BoxDecoration(
                color: const Color(0xFFC30000),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: const Color(0xFFC30000),
                  width: 0.8,
                ),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 9.0,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabBody(_NotificationTab tab) {
    final items = _itemsFor(tab);
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No notifications yet.',
          style: FlutterFlowTheme.of(context).bodyMedium,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsetsDirectional.fromSTEB(18.0, 18.0, 18.0, 24.0),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10.0),
      itemBuilder: (context, index) {
        final item = items[index];
        return _notificationTile(item);
      },
    );
  }

  Widget _notificationTile(_NotificationData item) {
    final theme = FlutterFlowTheme.of(context);
    final unread = !_readIds.contains(item.id);
    final toneColor = switch (item.tone) {
      _NoticeTone.caution => const Color(0xFFD84A3A),
      _NoticeTone.positive => const Color(0xFF28A745),
      _NoticeTone.info => _blue,
    };

    return InkWell(
      onTap: () => _markRead(item),
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: unread
                ? toneColor.withValues(alpha: 0.34)
                : const Color(0xFFE8EAF0),
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8.0,
              color: Color(0x12000000),
              offset: Offset(0.0, 3.0),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: toneColor.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(13.0),
              ),
              child: Icon(item.icon, color: toneColor, size: 20.0),
            ),
            const SizedBox(width: 11.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.bodyMedium.override(
                            font: TextStyle(
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.normal,
                              fontStyle: theme.bodyMedium.fontStyle,
                            ),
                            color: theme.primaryText,
                            fontSize: 13.3,
                            letterSpacing: 0.0,
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.normal,
                            fontStyle: theme.bodyMedium.fontStyle,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8.0,
                          height: 8.0,
                          decoration: const BoxDecoration(
                            color: _blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _closeReader() {
    safeSetState(() => _selected = null);
  }

  Widget _readerOverlay() {
    final item = _selected;
    if (item == null) return const SizedBox.shrink();
    final theme = FlutterFlowTheme.of(context);
    final toneColor = switch (item.tone) {
      _NoticeTone.caution => const Color(0xFFD84A3A),
      _NoticeTone.positive => const Color(0xFF28A745),
      _NoticeTone.info => _blue,
    };
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.08),
        alignment: Alignment.topCenter,
        padding: const EdgeInsetsDirectional.fromSTEB(18.0, 80.0, 18.0, 0.0),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsetsDirectional.fromSTEB(16.0, 15.0, 16.0, 15.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 22.0,
                  color: Color(0x22000000),
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42.0,
                      height: 42.0,
                      decoration: BoxDecoration(
                        color: toneColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Icon(item.icon, color: toneColor, size: 21.0),
                    ),
                    const SizedBox(width: 11.0),
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.titleSmall.override(
                          font: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontStyle: theme.titleSmall.fontStyle,
                          ),
                          color: theme.primaryText,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w800,
                          fontStyle: theme.titleSmall.fontStyle,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _closeReader,
                      icon: const Icon(Icons.close_rounded, color: _blue),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  item.body,
                  style: GoogleFonts.inter(
                    color: theme.primaryText,
                    fontSize: 13.0,
                    height: 1.35,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'Today',
                  style: GoogleFonts.inter(
                    color: theme.secondaryText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          onPressed: () => context.goNamed(DashboardWidget.routeName),
        ),
        title: Text(
          'Notifications',
          style: theme.titleSmall.override(
            font: TextStyle(
              fontWeight: FontWeight.w800,
              fontStyle: theme.titleSmall.fontStyle,
            ),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w800,
            fontStyle: theme.titleSmall.fontStyle,
          ),
        ),
        centerTitle: true,
        actions: [
          FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            buttonSize: 52.0,
            icon:
                const Icon(Icons.description_rounded, color: _blue, size: 22.0),
            onPressed: () => context.pushNamed(VersionHistoryWidget.routeName),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  margin: const EdgeInsetsDirectional.fromSTEB(
                      18.0, 8.0, 18.0, 0.0),
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: theme.secondaryText,
                    indicator: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(11.0),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: theme.bodySmall.override(
                      font: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontStyle: theme.bodySmall.fontStyle,
                      ),
                      fontSize: 11.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w700,
                      fontStyle: theme.bodySmall.fontStyle,
                    ),
                    tabs: [
                      _tabLabel('Update', _NotificationTab.updates),
                      _tabLabel('Notice', _NotificationTab.notice),
                      _tabLabel('General', _NotificationTab.general),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _tabBody(_NotificationTab.updates),
                      _tabBody(_NotificationTab.notice),
                      _tabBody(_NotificationTab.general),
                    ],
                  ),
                ),
              ],
            ),
            _readerOverlay(),
          ],
        ),
      ),
    );
  }
}

enum _NotificationTab { updates, notice, general }

enum _NoticeTone { info, caution, positive }

class _NotificationData {
  const _NotificationData({
    required this.id,
    required this.tab,
    required this.title,
    required this.body,
    required this.icon,
    required this.tone,
  });

  final String id;
  final _NotificationTab tab;
  final String title;
  final String body;
  final IconData icon;
  final _NoticeTone tone;
}
