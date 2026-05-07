import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child});
  final Widget child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    _shouldShow = !kIsWeb && Platform.isIOS;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInCubic),
    );
    if (_shouldShow) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 380));
        if (!mounted) return;
        await _controller.forward();
        if (!mounted) return;
        setState(() => _shouldShow = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return widget.child;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final dark = brightness == Brightness.dark;
    final bg = dark ? AppTokens.bgDark : AppTokens.bgLight;
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (ctx, _) => IgnorePointer(
            child: Opacity(
              opacity: 1.0 - _fade.value,
              child: Container(
                color: bg,
                child: Center(
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Image.asset(
                      'assets/widget/launch_icon.png',
                      width: 120,
                      height: 120,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 120,
                        height: 120,
                      ),
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
