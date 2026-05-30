import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    duration: const Duration(milliseconds: 450),
  );
  bool _showVisual = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _showVisual = !kIsWeb && Platform.isIOS;
    _start();
  }

  Future<void> _start() async {
    if (_showVisual) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      await _fade.forward();
      if (!mounted) return;
      setState(() => _gone = true);
      splashFinished.value = true;
    } else {
      _gone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        splashFinished.value = true;
      });
    }
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
          IgnorePointer(
            child: FadeTransition(
              opacity: ReverseAnimation(
                CurvedAnimation(parent: _fade, curve: Curves.easeOut),
              ),
              child: Container(
                color: palette.bg,
                alignment: Alignment.center,
                child: Container(
                  width: splashIconSize,
                  height: splashIconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.28),
                        blurRadius: 36,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/widget/launch_icon.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => Container(
                      color: palette.accent,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.mosque,
                        color: palette.accentOn,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
