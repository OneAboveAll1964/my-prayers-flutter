import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

void showAppToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final palette = context.palette;
  final media = MediaQuery.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      return _AppToast(
        message: message,
        bg: palette.surface3,
        border: palette.line,
        text: palette.text,
        bottomPadding: media.padding.bottom + 24,
        duration: duration,
        onFinished: () {
          if (entry.mounted) entry.remove();
        },
      );
    },
  );
  overlay.insert(entry);
}

class _AppToast extends StatefulWidget {
  const _AppToast({
    required this.message,
    required this.bg,
    required this.border,
    required this.text,
    required this.bottomPadding,
    required this.duration,
    required this.onFinished,
  });

  final String message;
  final Color bg;
  final Color border;
  final Color text;
  final double bottomPadding;
  final Duration duration;
  final VoidCallback onFinished;

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _ctrl.reverse();
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: widget.bottomPadding,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _ctrl,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _ctrl, curve: AppTokens.ease)),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: widget.border),
                  ),
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: widget.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
