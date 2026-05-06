import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

enum AppButtonVariant { solid, outline, ghost, soft, danger }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.solid,
    this.size = AppButtonSize.md,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final disabled = widget.onPressed == null;

    final height = switch (widget.size) {
      AppButtonSize.sm => 36.0,
      AppButtonSize.md => 44.0,
      AppButtonSize.lg => 52.0,
    };
    final fontSize = switch (widget.size) {
      AppButtonSize.sm => 13.5,
      AppButtonSize.md => 15.0,
      AppButtonSize.lg => 16.0,
    };
    final hPad = switch (widget.size) {
      AppButtonSize.sm => 14.0,
      AppButtonSize.md => 18.0,
      AppButtonSize.lg => 22.0,
    };

    final (bg, fg, border) = switch (widget.variant) {
      AppButtonVariant.solid => (palette.accent, palette.accentOn, palette.accent),
      AppButtonVariant.outline => (palette.surface, palette.text, palette.lineStrong),
      AppButtonVariant.ghost => (Colors.transparent, palette.text, Colors.transparent),
      AppButtonVariant.soft => (palette.accentSoft, palette.accentStrong, palette.accentSoft),
      AppButtonVariant.danger => (Colors.transparent, palette.danger, palette.line),
    };

    final pressed = _down && !disabled;
    final pressedBg = switch (widget.variant) {
      AppButtonVariant.solid => palette.accentStrong,
      AppButtonVariant.outline => palette.surface2,
      AppButtonVariant.ghost => palette.surface2,
      AppButtonVariant.soft => palette.surface2,
      AppButtonVariant.danger => palette.surface2,
    };

    final showBg = pressed ? pressedBg : bg;
    final disabledBg = palette.surface3;
    final disabledFg = palette.textSubtle;

    final child = AnimatedScale(
      scale: pressed ? 0.985 : 1,
      duration: AppTokens.durationFast,
      curve: AppTokens.ease,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        curve: AppTokens.ease,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        decoration: BoxDecoration(
          color: disabled ? disabledBg : showBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: disabled ? disabledBg : (widget.variant == AppButtonVariant.solid ? showBg : border),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon,
                  size: fontSize + 1, color: disabled ? disabledFg : fg),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: disabled ? disabledFg : fg,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.05,
                ),
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
    this.tapSize = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? semanticLabel;
  final double tapSize;

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
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        width: widget.tapSize,
        height: widget.tapSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _down ? palette.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Semantics(
          button: true,
          label: widget.semanticLabel,
          child: Icon(widget.icon, size: widget.size, color: color),
        ),
      ),
    );
  }
}
