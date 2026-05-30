import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

final splashFinished = ValueNotifier<bool>(false);

const splashIconSize = 120.0;

double get splashHandoffSize => (!kIsWeb && Platform.isAndroid) ? 179.0 : 120.0;

Offset splashIconCenter(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return Offset(size.width / 2, size.height / 2);
}

class SplashOverlay extends StatefulWidget {
  const SplashOverlay({
    super.key,
    required this.child,
    this.animateReveal = false,
  });
  final Widget child;
  final bool animateReveal;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  bool _showVisual = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _showVisual = !kIsWeb && (Platform.isIOS || Platform.isAndroid);
    _start();
  }

  Future<void> _start() async {
    final hold = widget.animateReveal ? 350 : 650;
    if (_showVisual) {
      await Future<void>.delayed(Duration(milliseconds: hold));
      if (!mounted) return;
      await _fade.forward();
      if (!mounted) return;
      setState(() => _gone = true);
      splashFinished.value = true;
    } else {
      _gone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 120));
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
    final center = splashIconCenter(context);

    Widget icon = Container(
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/widget/launch_icon.png',
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Container(
          color: palette.accent,
          alignment: Alignment.center,
          child: Icon(Icons.mosque, color: palette.accentOn, size: 56),
        ),
      ),
    );
    if (widget.animateReveal) {
      icon = AnimatedBuilder(
        animation: _fade,
        builder: (context, child) {
          final e = Curves.easeIn.transform(_fade.value);
          return Transform.scale(scale: 1 + 0.12 * e, child: child);
        },
        child: icon,
      );
    }

    Widget content = widget.child;
    if (widget.animateReveal && !_gone) {
      content = AnimatedBuilder(
        animation: _fade,
        builder: (context, child) {
          final e = Curves.easeOut.transform(_fade.value);
          return Transform.scale(scale: 1.04 - 0.04 * e, child: child);
        },
        child: content,
      );
    }

    return Stack(
      children: [
        content,
        if (!_gone)
          IgnorePointer(
            child: FadeTransition(
              opacity: ReverseAnimation(
                CurvedAnimation(parent: _fade, curve: Curves.easeOut),
              ),
              child: Container(
                color: palette.bg,
                child: Stack(
                  children: [
                    Positioned(
                      left: center.dx - splashHandoffSize / 2,
                      top: center.dy - splashHandoffSize / 2,
                      width: splashHandoffSize,
                      height: splashHandoffSize,
                      child: icon,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
