import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(bottom: BorderSide(color: palette.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: back
                    ? IconButton(
                        icon: Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_back_rounded,
                          color: palette.text,
                          size: 22,
                        ),
                        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: palette.textSubtle,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          if (search != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: search!,
            ),
        ],
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
      padding: padding ?? const EdgeInsets.fromLTRB(18, 8, 18, 24),
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
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
