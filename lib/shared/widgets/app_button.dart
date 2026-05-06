import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

enum AppButtonVariant { solid, outline, ghost, danger }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.solid,
    this.icon,
    this.expand = false,
    this.height = 44,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final disabled = widget.onPressed == null;

    final (bg, fg, border) = switch (widget.variant) {
      AppButtonVariant.solid => (palette.accent, palette.accentOn, palette.accent),
      AppButtonVariant.outline => (palette.surface, palette.text, palette.line),
      AppButtonVariant.ghost => (Colors.transparent, palette.text, Colors.transparent),
      AppButtonVariant.danger => (palette.danger, Colors.white, palette.danger),
    };

    final pressed = _down && !disabled;
    final showBg = pressed
        ? (widget.variant == AppButtonVariant.solid
            ? palette.accentStrong
            : (widget.variant == AppButtonVariant.danger
                ? palette.danger
                : palette.surface2))
        : bg;

    final child = AnimatedScale(
      scale: pressed ? 0.985 : 1,
      duration: AppTokens.durationFast,
      curve: AppTokens.ease,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        curve: AppTokens.ease,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: disabled ? palette.surface2 : showBg,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: widget.variant == AppButtonVariant.outline
              ? Border.all(color: border)
              : null,
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon,
                  size: 16, color: disabled ? palette.textSubtle : fg),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: TextStyle(
                color: disabled ? palette.textSubtle : fg,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTapDown: (_) {
        if (!disabled) setState(() => _down = true);
      },
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: widget.expand ? SizedBox(width: double.infinity, child: child) : child,
    );
  }
}

class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 22,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? semanticLabel;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = widget.color ?? palette.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: AppTokens.durationFast,
        curve: AppTokens.ease,
        child: Semantics(
          button: true,
          label: widget.semanticLabel,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(widget.icon, size: widget.size, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
