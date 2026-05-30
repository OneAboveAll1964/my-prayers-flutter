import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/theme/tokens.dart';

final splashFinished = ValueNotifier<bool>(false);

const splashIconSize = 120.0;

class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child});
  final Widget child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    await _fade.forward();
    if (!mounted) return;
    setState(() => _gone = true);
    splashFinished.value = true;
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      children: [
        widget.child,
        if (!_gone)
          FadeTransition(
            opacity: ReverseAnimation(
              CurvedAnimation(parent: _fade, curve: Curves.easeOut),
            ),
            child: Container(
              color: palette.bg,
              alignment: Alignment.center,
              child: _SplashContent(),
            ),
          ),
      ],
    );
  }
}

class _SplashContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: splashIconSize,
          height: splashIconSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/widget/launch_icon.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: palette.accent,
              alignment: Alignment.center,
              child: Icon(Icons.mosque, color: palette.accentOn, size: 60),
            ),
          ),
        ),
      ],
    );
  }
}
