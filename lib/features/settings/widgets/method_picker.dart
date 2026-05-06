import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/prayer_time.dart';
import '../../../shared/state/settings_provider.dart';
import '../../../shared/widgets/page_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MethodPicker extends ConsumerWidget {
  const MethodPicker({super.key, this.onPick});
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final selected = ref.watch(settingsProvider).calculationMethod;

    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < CalculationMethod.values.length; i++) ...[
            _MethodRow(
              label: l10n.t('calc.${CalculationMethod.values[i].name}'),
              selected: CalculationMethod.values[i] == selected,
              onTap: () {
                ref
                    .read(settingsProvider.notifier)
                    .setCalculationMethod(CalculationMethod.values[i]);
                onPick?.call();
              },
            ),
            if (i < CalculationMethod.values.length - 1)
              Container(height: 1, color: palette.line),
          ],
        ],
      ),
    );
  }
}

class _MethodRow extends StatefulWidget {
  const _MethodRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_MethodRow> createState() => _MethodRowState();
}

class _MethodRowState extends State<_MethodRow> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        color: _down ? palette.surface2 : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.selected)
              Icon(LucideIcons.check, color: palette.accent, size: 20),
          ],
        ),
      ),
    );
  }
}
