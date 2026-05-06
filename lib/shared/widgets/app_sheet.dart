import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext) builder,
}) {
  final palette = context.palette;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.4),
    backgroundColor: Colors.transparent,
    elevation: 0,
    useSafeArea: false,
    useRootNavigator: true,
    showDragHandle: false,
    constraints: const BoxConstraints(),
    builder: (ctx) {
      return _SheetBody(
        title: title,
        bgColor: palette.surface,
        lineColor: palette.line,
        lineStrongColor: palette.lineStrong,
        textColor: palette.text,
        child: Builder(builder: builder),
      );
    },
  );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.title,
    required this.bgColor,
    required this.lineColor,
    required this.lineStrongColor,
    required this.textColor,
    required this.child,
  });

  final String title;
  final Color bgColor;
  final Color lineColor;
  final Color lineStrongColor;
  final Color textColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: media.size.height - media.padding.top - 24,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: lineColor)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: lineStrongColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.17,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    16, 4, 16, 20 + media.padding.bottom),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
