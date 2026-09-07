import 'dart:async';

import '/components/status_action_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'onboarding_model.dart';
export 'onboarding_model.dart';

class OnboardingWidget extends StatefulWidget {
  const OnboardingWidget({super.key});

  static String routeName = 'onboarding';
  static String routePath = 'onboarding';

  @override
  State<OnboardingWidget> createState() => _OnboardingWidgetState();
}

class _OnboardingWidgetState extends State<OnboardingWidget> {
  late OnboardingModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _slideTimer;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OnboardingModel());
    _model.pageViewController = PageController(initialPage: 0);
    _slideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final controller = _model.pageViewController;
      if (!mounted || controller == null || !controller.hasClients) return;
      final nextPage = (_model.pageViewCurrentIndex + 1) % _slides.length;
      controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _model.dispose();
    super.dispose();
  }

  static const _slides = [
    _IntroSlideData(
      image: 'assets/images/1_(For_Blue).png',
      title: 'Send Money',
      body: 'Send crypto, receive cash instantly.',
      action: 'Start Now',
      dark: true,
    ),
    _IntroSlideData(
      image: 'assets/images/2_(For_White).png',
      title: 'Receive Payment',
      body: 'Get paid your way, in crypto or local currency.',
      action: 'Start Now',
      dark: true,
    ),
    _IntroSlideData(
      image: 'assets/images/2settle_illustration.jpg',
      title: 'Integrate with Business',
      body: 'Accept payments and automate settlements globally.',
      action: 'Start Now',
      dark: false,
    ),
  ];

  void _openLogin() {
    _slideTimer?.cancel();
    context.pushNamed(
      LoginWidget.routeName,
      extra: <String, dynamic>{
        kTransitionInfoKey: const TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.rightToLeft,
        ),
      },
    );
  }

  void _stopAutoSlide() {
    _slideTimer?.cancel();
    _slideTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.secondaryBackground,
      body: PageView.builder(
        controller: _model.pageViewController,
        scrollDirection: Axis.horizontal,
        itemCount: _slides.length,
        onPageChanged: (_) => safeSetState(() {}),
        itemBuilder: (context, index) {
          final slide = _slides[index];
          return _IntroSlide(
            index: index,
            data: slide,
            onStartPressed: _stopAutoSlide,
            onAuthPressed: _openLogin,
          );
        },
      ),
    );
  }
}

class _IntroSlideData {
  const _IntroSlideData({
    required this.image,
    required this.title,
    required this.body,
    required this.action,
    required this.dark,
  });

  final String image;
  final String title;
  final String body;
  final String action;
  final bool dark;
}

class _IntroSlide extends StatefulWidget {
  const _IntroSlide({
    required this.index,
    required this.data,
    required this.onStartPressed,
    required this.onAuthPressed,
  });

  final int index;
  final _IntroSlideData data;
  final VoidCallback onStartPressed;
  final VoidCallback onAuthPressed;

  @override
  State<_IntroSlide> createState() => _IntroSlideState();
}

class _IntroSlideState extends State<_IntroSlide> {
  bool _isStarting = false;
  bool _isStarted = false;

  Future<void> _handleStartNow() async {
    if (_isStarting) {
      return;
    }

    widget.onStartPressed();
    safeSetState(() {
      _isStarting = true;
      _isStarted = false;
    });
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) {
      return;
    }
    safeSetState(() => _isStarted = true);
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) {
      return;
    }
    widget.onAuthPressed();
    if (!mounted) return;
    safeSetState(() {
      _isStarting = false;
      _isStarted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = widget.data.dark;
    final foreground = isDark ? Colors.white : theme.primaryText;
    final muted = isDark ? const Color(0xD9FFFFFF) : theme.secondaryText;
    final background = isDark ? theme.primary : theme.secondaryBackground;
    final height = MediaQuery.sizeOf(context).height;
    final imageHeight = (height * 0.38).clamp(240.0, 360.0);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: background,
      child: SafeArea(
        top: true,
        bottom: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24.0, 18.0, 24.0, 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                widget.data.image,
                width: double.infinity,
                height: imageHeight,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28.0),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  widget.data.title,
                  style: FlutterFlowTheme.of(context).displaySmall.override(
                        font: TextStyle(
                          fontWeight: FlutterFlowTheme.of(context)
                              .displaySmall
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .displaySmall
                              .fontStyle,
                        ),
                        color: foreground,
                        fontSize: 20.0,
                        letterSpacing: 0.0,
                        fontWeight: FlutterFlowTheme.of(context)
                            .displaySmall
                            .fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).displaySmall.fontStyle,
                      ),
                ),
              ),
              const SizedBox(height: 10.0),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  widget.data.body,
                  style: FlutterFlowTheme.of(context).titleSmall.override(
                        font: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleSmall.fontStyle,
                        ),
                        color: muted,
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.normal,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleSmall.fontStyle,
                      ),
                ),
              ),
              const SizedBox(height: 22.0),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: StatusActionButton(
                  text: widget.data.action,
                  isLoading: _isStarting && !_isStarted,
                  isDone: _isStarted,
                  onPressed: _handleStartNow,
                  idleIcon: Icons.start_rounded,
                  backgroundColor: isDark ? Colors.white : theme.primary,
                  textColor: isDark ? theme.primary : Colors.white,
                  iconBackgroundColor: isDark ? theme.primary : Colors.white,
                  iconColor: isDark ? Colors.white : theme.primary,
                ),
              ),
              if (widget.index == 1) ...[
                const SizedBox(height: 12.0),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InkWell(
                    onTap: () {
                      widget.onStartPressed();
                      context.pushNamed(DashboardWidget.routeName);
                    },
                    borderRadius: BorderRadius.circular(10.0),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          4.0, 6.0, 10.0, 6.0),
                      child: Text(
                        'Skip to dashboard',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                              color: foreground.withValues(alpha: 0.86),
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .fontStyle,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
