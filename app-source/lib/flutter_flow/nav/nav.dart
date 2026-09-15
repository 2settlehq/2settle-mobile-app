import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/base_auth_user_provider.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Whether the real 2Settle backend session (OTP login + app-PIN unlock,
  /// see AuthService/PinService) is active for this app launch. This is
  /// the actual auth signal for this app's route guards — [user]/Firebase
  /// auth state is legacy FlutterFlow scaffolding the real login flow
  /// never touches, so `loggedIn` below is OR'd with this instead of
  /// relying on Firebase alone. Defaults to false on every cold start, so
  /// a direct deep link into an authenticated route can't skip the
  /// unlock/login screens.
  bool _appSessionActive = false;
  void setAppSessionActive(bool active) {
    if (_appSessionActive == active) return;
    _appSessionActive = active;
    notifyListeners();
  }

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => (user?.loggedIn ?? false) || _appSessionActive;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) =>
          appStateNotifier.loggedIn ? DashboardWidget() : SplashScreenWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => appStateNotifier.loggedIn
              ? DashboardWidget()
              : SplashScreenWidget(),
          routes: [
            FFRoute(
              name: SplashScreenWidget.routeName,
              path: SplashScreenWidget.routePath,
              builder: (context, params) => SplashScreenWidget(),
            ),
            FFRoute(
              name: OnboardingWidget.routeName,
              path: OnboardingWidget.routePath,
              builder: (context, params) => OnboardingWidget(),
            ),
            FFRoute(
              name: MainTransactionWidget.routeName,
              path: MainTransactionWidget.routePath,
              requireAuth: true,
              builder: (context, params) => MainTransactionWidget(),
            ),
            FFRoute(
              name: SettingsWidget.routeName,
              path: SettingsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => SettingsWidget(),
            ),
            FFRoute(
              name: AccountWidget.routeName,
              path: AccountWidget.routePath,
              requireAuth: true,
              builder: (context, params) => AccountWidget(),
            ),
            FFRoute(
              name: AllServicesWidget.routeName,
              path: AllServicesWidget.routePath,
              requireAuth: true,
              builder: (context, params) => AllServicesWidget(),
            ),
            FFRoute(
              name: WaleSpendWidget.routeName,
              path: WaleSpendWidget.routePath,
              requireAuth: true,
              builder: (context, params) => WaleSpendWidget(),
            ),
            FFRoute(
              name: GiftWidget.routeName,
              path: GiftWidget.routePath,
              requireAuth: true,
              builder: (context, params) => GiftWidget(),
            ),
            FFRoute(
              name: ClaimGiftWidget.routeName,
              path: ClaimGiftWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ClaimGiftWidget(),
            ),
            FFRoute(
              name: CreateGiftWidget.routeName,
              path: CreateGiftWidget.routePath,
              requireAuth: true,
              builder: (context, params) => CreateGiftWidget(),
            ),
            FFRoute(
              name: GiftCreatedWidget.routeName,
              path: GiftCreatedWidget.routePath,
              requireAuth: true,
              builder: (context, params) => GiftCreatedWidget(
                amount: params.getParam<String>(
                      'amount',
                      ParamType.String,
                    ) ??
                    '0',
                crypto: params.getParam<String>(
                      'crypto',
                      ParamType.String,
                    ) ??
                    'USDT',
                network: params.getParam<String>(
                      'network',
                      ParamType.String,
                    ) ??
                    'TRC20',
                cryptoAmount: params.getParam<String>(
                      'cryptoAmount',
                      ParamType.String,
                    ) ??
                    '0.00000 USDT',
                reference: params.getParam<String>(
                      'reference',
                      ParamType.String,
                    ) ??
                    '',
                paymentId: params.getParam<String>(
                      'paymentId',
                      ParamType.String,
                    ) ??
                    '',
                depositAddress: params.getParam<String>(
                      'depositAddress',
                      ParamType.String,
                    ) ??
                    '',
                status: params.getParam<String>(
                      'status',
                      ParamType.String,
                    ) ??
                    'pending',
                expiresAt: params.getParam<String>(
                      'expiresAt',
                      ParamType.String,
                    ) ??
                    '',
                chargeFiat: params.getParam<String>(
                      'chargeFiat',
                      ParamType.String,
                    ) ??
                    '',
                chargeCrypto: params.getParam<String>(
                      'chargeCrypto',
                      ParamType.String,
                    ) ??
                    '',
                rate: params.getParam<String>(
                      'rate',
                      ParamType.String,
                    ) ??
                    '',
                transactionUsd: params.getParam<String>(
                      'transactionUsd',
                      ParamType.String,
                    ) ??
                    '',
              ),
            ),
            FFRoute(
              name: ConfirmGiftClaimWidget.routeName,
              path: ConfirmGiftClaimWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ConfirmGiftClaimWidget(
                reference: params.getParam<String>(
                      'reference',
                      ParamType.String,
                    ) ??
                    '',
                amount: params.getParam<String>(
                      'amount',
                      ParamType.String,
                    ) ??
                    '₦0',
                bankName: params.getParam<String>(
                      'bankName',
                      ParamType.String,
                    ) ??
                    'Bank',
                accountNumber: params.getParam<String>(
                      'accountNumber',
                      ParamType.String,
                    ) ??
                    '',
                accountName: params.getParam<String>(
                      'accountName',
                      ParamType.String,
                    ) ??
                    'Receiver',
                bankCode: params.getParam<String>(
                      'bankCode',
                      ParamType.String,
                    ) ??
                    '',
              ),
            ),
            FFRoute(
              name: GiftClaimDetailsWidget.routeName,
              path: GiftClaimDetailsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => GiftClaimDetailsWidget(
                reference: params.getParam<String>(
                      'reference',
                      ParamType.String,
                    ) ??
                    '',
                amount: params.getParam<String>(
                      'amount',
                      ParamType.String,
                    ) ??
                    '₦0',
                bankName: params.getParam<String>(
                      'bankName',
                      ParamType.String,
                    ) ??
                    'Bank',
                accountNumber: params.getParam<String>(
                      'accountNumber',
                      ParamType.String,
                    ) ??
                    '',
                accountName: params.getParam<String>(
                      'accountName',
                      ParamType.String,
                    ) ??
                    'Receiver',
                bankCode: params.getParam<String>(
                      'bankCode',
                      ParamType.String,
                    ) ??
                    '',
                status: params.getParam<String>(
                      'status',
                      ParamType.String,
                    ) ??
                    'settling',
                createdAt: params.getParam<String>(
                      'createdAt',
                      ParamType.String,
                    ) ??
                    '',
                settlingStartedAt: params.getParam<String>(
                      'settlingStartedAt',
                      ParamType.String,
                    ) ??
                    '',
                settledAt: params.getParam<String>(
                      'settledAt',
                      ParamType.String,
                    ) ??
                    '',
                settlementDuration: params.getParam<String>(
                      'settlementDuration',
                      ParamType.String,
                    ) ??
                    '',
                type: params.getParam<String>(
                      'type',
                      ParamType.String,
                    ) ??
                    '',
                crypto: params.getParam<String>(
                      'crypto',
                      ParamType.String,
                    ) ??
                    'USDT',
                network: params.getParam<String>(
                      'network',
                      ParamType.String,
                    ) ??
                    'TRC20',
                cryptoAmount: params.getParam<String>(
                      'cryptoAmount',
                      ParamType.String,
                    ) ??
                    '',
                paymentId: params.getParam<String>(
                      'paymentId',
                      ParamType.String,
                    ) ??
                    '',
                depositAddress: params.getParam<String>(
                      'depositAddress',
                      ParamType.String,
                    ) ??
                    '',
                expiresAt: params.getParam<String>(
                      'expiresAt',
                      ParamType.String,
                    ) ??
                    '',
                chargeFiat: params.getParam<String>(
                      'chargeFiat',
                      ParamType.String,
                    ) ??
                    '',
                chargeCrypto: params.getParam<String>(
                      'chargeCrypto',
                      ParamType.String,
                    ) ??
                    '',
                rate: params.getParam<String>(
                      'rate',
                      ParamType.String,
                    ) ??
                    '',
                transactionUsd: params.getParam<String>(
                      'transactionUsd',
                      ParamType.String,
                    ) ??
                    '',
              ),
            ),
            FFRoute(
              name: SecurityWidget.routeName,
              path: SecurityWidget.routePath,
              requireAuth: true,
              builder: (context, params) => SecurityWidget(),
            ),
            FFRoute(
              name: SetAppPasscodeWidget.routeName,
              path: SetAppPasscodeWidget.routePath,
              requireAuth: true,
              builder: (context, params) => SetAppPasscodeWidget(
                mode: params.getParam<String>(
                      'mode',
                      ParamType.String,
                    ) ??
                    'set',
              ),
            ),
            FFRoute(
              name: NotificationSettingsWidget.routeName,
              path: NotificationSettingsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => NotificationSettingsWidget(),
            ),
            FFRoute(
              name: NotificationsWidget.routeName,
              path: NotificationsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => NotificationsWidget(),
            ),
            FFRoute(
              name: VersionHistoryWidget.routeName,
              path: VersionHistoryWidget.routePath,
              requireAuth: true,
              builder: (context, params) => VersionHistoryWidget(),
            ),
            FFRoute(
              name: HistoryWidget.routeName,
              path: HistoryWidget.routePath,
              requireAuth: true,
              builder: (context, params) => HistoryWidget(),
            ),
            FFRoute(
              name: TransactionDetailsWidget.routeName,
              path: TransactionDetailsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => TransactionDetailsWidget(
                id: params.getParam<String>(
                      'id',
                      ParamType.String,
                    ) ??
                    '',
                createdAt: params.getParam<String>(
                      'createdAt',
                      ParamType.String,
                    ) ??
                    '',
                settlementAmount: params.getParam<String>(
                      'settlementAmount',
                      ParamType.String,
                    ) ??
                    '0.00',
                cryptoAmount: params.getParam<String>(
                      'cryptoAmount',
                      ParamType.String,
                    ) ??
                    '0.00000 USDT',
                crypto: params.getParam<String>(
                      'crypto',
                      ParamType.String,
                    ) ??
                    'USDT',
                network: params.getParam<String>(
                      'network',
                      ParamType.String,
                    ) ??
                    'TRC20',
                beneficiaryName: params.getParam<String>(
                      'beneficiaryName',
                      ParamType.String,
                    ) ??
                    'Beneficiary',
                bankName: params.getParam<String>(
                      'bankName',
                      ParamType.String,
                    ) ??
                    'Bank',
                accountNumber: params.getParam<String>(
                      'accountNumber',
                      ParamType.String,
                    ) ??
                    '',
                rate: params.getParam<String>(
                      'rate',
                      ParamType.String,
                    ) ??
                    '...',
                status: params.getParam<String>(
                      'status',
                      ParamType.String,
                    ) ??
                    'funding',
              ),
            ),
            FFRoute(
              name: ConfirmationPageWidget.routeName,
              path: ConfirmationPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ConfirmationPageWidget(
                settlementAmount: params.getParam<String>(
                      'settlementAmount',
                      ParamType.String,
                    ) ??
                    '0.00',
                cryptoAmount: params.getParam<String>(
                      'cryptoAmount',
                      ParamType.String,
                    ) ??
                    '0.00000 USDT',
                crypto: params.getParam<String>(
                      'crypto',
                      ParamType.String,
                    ) ??
                    'USDT',
                network: params.getParam<String>(
                      'network',
                      ParamType.String,
                    ) ??
                    'TRC20',
                beneficiaryName: params.getParam<String>(
                      'beneficiaryName',
                      ParamType.String,
                    ) ??
                    'Beneficiary',
                bankName: params.getParam<String>(
                      'bankName',
                      ParamType.String,
                    ) ??
                    'Bank',
                accountNumber: params.getParam<String>(
                      'accountNumber',
                      ParamType.String,
                    ) ??
                    '',
                rate: params.getParam<String>(
                      'rate',
                      ParamType.String,
                    ) ??
                    '...',
              ),
            ),
            FFRoute(
              name: ProfileDetailsWidget.routeName,
              path: ProfileDetailsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ProfileDetailsWidget(),
            ),
            FFRoute(
              name: AccountDetailsWidget.routeName,
              path: AccountDetailsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => AccountDetailsWidget(
                origin: params.getParam<String>(
                      'origin',
                      ParamType.String,
                    ) ??
                    'home',
              ),
            ),
            FFRoute(
              name: LoginWidget.routeName,
              path: LoginWidget.routePath,
              builder: (context, params) => LoginWidget(
                mode: params.getParam<String>(
                      'mode',
                      ParamType.String,
                    ) ??
                    'connect',
              ),
            ),
            FFRoute(
              name: ConfirmCodeWidget.routeName,
              path: ConfirmCodeWidget.routePath,
              builder: (context, params) => ConfirmCodeWidget(
                mode: params.getParam<String>(
                      'mode',
                      ParamType.String,
                    ) ??
                    'confirm',
              ),
            ),
            FFRoute(
              name: DashboardWidget.routeName,
              path: DashboardWidget.routePath,
              requireAuth: true,
              builder: (context, params) => DashboardWidget(),
            ),
            FFRoute(
              name: PayPageWidget.routeName,
              path: PayPageWidget.routePath,
              requireAuth: true,
              builder: (context, params) => PayPageWidget(),
            ),
            FFRoute(
              name: ReceivePaymentDetailsWidget.routeName,
              path: ReceivePaymentDetailsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ReceivePaymentDetailsWidget(),
            ),
            FFRoute(
              name: ReceiveNairaAccountWidget.routeName,
              path: ReceiveNairaAccountWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ReceiveNairaAccountWidget(),
            ),
            FFRoute(
              name: ReceiveDollarAccountWidget.routeName,
              path: ReceiveDollarAccountWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ReceiveDollarAccountWidget(),
            ),
            FFRoute(
              name: ReceiveCryptoWalletWidget.routeName,
              path: ReceiveCryptoWalletWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ReceiveCryptoWalletWidget(),
            ),
            FFRoute(
              name: ReceiveRequestDetailsWidget.routeName,
              path: ReceiveRequestDetailsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ReceiveRequestDetailsWidget(
                requestId: params.getParam<String>(
                      'requestId',
                      ParamType.String,
                    ) ??
                    '',
              ),
            ),
            FFRoute(
              name: ConvertWidget.routeName,
              path: ConvertWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ConvertWidget(),
            ),
            FFRoute(
              name: MyCardsWidget.routeName,
              path: MyCardsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => MyCardsWidget(),
            ),
            FFRoute(
              name: CardDetailsWidget.routeName,
              path: CardDetailsWidget.routePath,
              requireAuth: true,
              builder: (context, params) => CardDetailsWidget(),
            ),
            FFRoute(
              name: ReceiveFundingWidget.routeName,
              path: ReceiveFundingWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ReceiveFundingWidget(
                settlementAmount: params.getParam<String>(
                      'settlementAmount',
                      ParamType.String,
                    ) ??
                    '0.00',
                cryptoAmount: params.getParam<String>(
                      'cryptoAmount',
                      ParamType.String,
                    ) ??
                    '0.00000 USDT',
                crypto: params.getParam<String>(
                      'crypto',
                      ParamType.String,
                    ) ??
                    'USDT',
                network: params.getParam<String>(
                      'network',
                      ParamType.String,
                    ) ??
                    'TRC20',
                beneficiaryName: params.getParam<String>(
                      'beneficiaryName',
                      ParamType.String,
                    ) ??
                    'Beneficiary',
                bankName: params.getParam<String>(
                      'bankName',
                      ParamType.String,
                    ) ??
                    'Bank',
                accountNumber: params.getParam<String>(
                      'accountNumber',
                      ParamType.String,
                    ) ??
                    '',
                rate: params.getParam<String>(
                      'rate',
                      ParamType.String,
                    ) ??
                    '...',
                purpose: params.getParam<String>(
                      'purpose',
                      ParamType.String,
                    ) ??
                    '',
                paymentId: params.getParam<String>(
                      'paymentId',
                      ParamType.String,
                    ) ??
                    '',
                reference: params.getParam<String>(
                      'reference',
                      ParamType.String,
                    ) ??
                    '',
                depositAddress: params.getParam<String>(
                      'depositAddress',
                      ParamType.String,
                    ) ??
                    '',
                paymentStatus: params.getParam<String>(
                      'paymentStatus',
                      ParamType.String,
                    ) ??
                    '',
                expiresAt: params.getParam<String>(
                      'expiresAt',
                      ParamType.String,
                    ) ??
                    '',
                chargeFiat: params.getParam<String>(
                      'chargeFiat',
                      ParamType.String,
                    ) ??
                    '',
                chargeCrypto: params.getParam<String>(
                      'chargeCrypto',
                      ParamType.String,
                    ) ??
                    '',
                transactionUsd: params.getParam<String>(
                      'transactionUsd',
                      ParamType.String,
                    ) ??
                    '',
              ),
            ),
            FFRoute(
              name: ConfirmTransactionWidget.routeName,
              path: ConfirmTransactionWidget.routePath,
              requireAuth: true,
              builder: (context, params) => ConfirmTransactionWidget(
                settlementAmount: params.getParam<String>(
                      'settlementAmount',
                      ParamType.String,
                    ) ??
                    '0.00',
                rate: params.getParam<String>(
                      'rate',
                      ParamType.String,
                    ) ??
                    '...',
                beneficiaryName: params.getParam<String>(
                      'beneficiaryName',
                      ParamType.String,
                    ) ??
                    'Beneficiary',
                bankName: params.getParam<String>(
                      'bankName',
                      ParamType.String,
                    ) ??
                    'Bank',
                accountNumber: params.getParam<String>(
                      'accountNumber',
                      ParamType.String,
                    ) ??
                    '',
                cryptoAmount: params.getParam<String>(
                      'cryptoAmount',
                      ParamType.String,
                    ) ??
                    '0.00000 USDT',
                crypto: params.getParam<String>(
                      'crypto',
                      ParamType.String,
                    ) ??
                    'USDT',
                network: params.getParam<String>(
                      'network',
                      ParamType.String,
                    ) ??
                    'TRC20',
              ),
            )
          ].map((r) => r.toRoute(appStateNotifier)).toList(),
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/splashScreen';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? Center(
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                )
              : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
