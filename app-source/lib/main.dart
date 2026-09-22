import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/pin_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();

  await FlutterFlowTheme.initialize();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  // How long the app can sit in the background before the next foreground
  // resume forces a PIN re-entry. 60s balances real security (a lost or
  // stolen unlocked phone isn't reachable for long) against not re-prompting
  // for routine interruptions — a quick camera/share-sheet trip, glancing at
  // a notification, a phone call.
  static const _autoLockAfter = Duration(seconds: 60);
  DateTime? _backgroundedAt;
  bool _lockScreenOpen = false;

  // Screens where a PIN prompt either doesn't make sense yet (no session/PIN
  // to protect) or would stomp on a flow already dealing with the PIN, so
  // auto-lock skips them rather than pushing another lock screen on top.
  static final _autoLockExemptRoutes = {
    '/${SplashScreenWidget.routePath}',
    '/${OnboardingWidget.routePath}',
    '/${LoginWidget.routePath}',
    '/${ConfirmCodeWidget.routePath}',
    '/${SetAppPasscodeWidget.routePath}',
  };

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;

  final authUserSub = authenticatedUserStream.listen((_) {});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = settleioFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    authUserSub.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_maybeAutoLock());
    }
  }

  Future<void> _maybeAutoLock() async {
    if (_lockScreenOpen) return;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) return;
    if (DateTime.now().difference(backgroundedAt) < _autoLockAfter) return;
    if (!await PinService.hasPin()) return;
    if (_autoLockExemptRoutes.contains(getRoute())) return;
    if (!mounted || _lockScreenOpen) return;
    _lockScreenOpen = true;
    try {
      await _router.pushNamed(
        ConfirmCodeWidget.routeName,
        queryParameters: {'mode': 'resume'},
      );
    } finally {
      _lockScreenOpen = false;
    }
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'settleio',
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.0,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Hornbill',
        fontFamilyFallback: const ['Inter', 'Roboto', 'Arial'],
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Hornbill',
        fontFamilyFallback: const ['Inter', 'Roboto', 'Arial'],
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
