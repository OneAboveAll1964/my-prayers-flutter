import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.back = false,
    this.action,
    this.search,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final bool back;
  final Widget? action;
  final Widget? search;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      color: palette.bg,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (back) ...[
                _BackButton(
                  onTap: onBack ?? () => _safePop(context),
                  isRtl: isRtl,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          if (search != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: search!,
            ),
        ],
      ),
    );
  }

  static void _safePop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

class _BackButton extends StatefulWidget {
  const _BackButton({required this.onTap, required this.isRtl});
  final VoidCallback onTap;
  final bool isRtl;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _down ? p.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          widget.isRtl ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
          color: p.text,
          size: 20,
        ),
      ),
    );
  }
}

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.gap = 14,
  });

  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final list = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      list.add(children[i]);
      if (i < children.length - 1) list.add(SizedBox(height: gap));
    }
    return ListView(
      controller: controller,
      padding: padding ?? const EdgeInsets.fromLTRB(18, 4, 18, 28),
      physics: const ClampingScrollPhysics(),
      children: list,
    );
  }
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.tone = SurfaceTone.surface,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final SurfaceTone tone;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: padding,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: tone == SurfaceTone.surface
            ? palette.surface
            : (tone == SurfaceTone.surface2 ? palette.surface2 : palette.surface3),
        borderRadius: borderRadius ?? BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.line),
      ),
      child: child,
    );
  }
}

enum SurfaceTone { surface, surface2, surface3 }

class TapRow extends StatefulWidget {
  const TapRow({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  State<TapRow> createState() => _TapRowState();
}

class _TapRowState extends State<TapRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (widget.onTap != null) setState(() => _down = true);
      },
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        padding: widget.padding,
        color: _down ? palette.surface2 : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}
