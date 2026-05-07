import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/models/prayer_time.dart';
import '../../../shared/widgets/page_scaffold.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: palette.textSubtle,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class SettingsTile extends StatefulWidget {
  const SettingsTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
  });
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
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
            if (widget.icon != null) ...[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(widget.icon, size: 17, color: palette.accentStrong),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              widget.label,
              style: TextStyle(
                color: palette.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: palette.textSubtle,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Ionicons.chevron_back
                  : Ionicons.chevron_forward,
              size: 18,
              color: palette.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: context.palette.line);
}

class OffsetEditor extends StatelessWidget {
  const OffsetEditor({
    super.key,
    required this.offsets,
    required this.onChange,
  });
  final List<int> offsets;
  final void Function(int, int) onChange;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < prayerKeys.length; i++) ...[
            _OffsetRow(
              label: l10n.t('prayers.${prayerKeys[i]}'),
              value: offsets[i],
              minutesLabel: l10n.t('settings.minutes'),
              onChange: (delta) {
                final next = (offsets[i] + delta).clamp(-30, 30);
                onChange(i, next);
              },
            ),
            if (i < prayerKeys.length - 1)
              Container(height: 1, color: palette.line),
          ],
        ],
      ),
    );
  }
}

class _OffsetRow extends StatelessWidget {
  const _OffsetRow({
    required this.label,
    required this.value,
    required this.minutesLabel,
    required this.onChange,
  });

  final String label;
  final int value;
  final String minutesLabel;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final canMinus = value > -30;
    final canPlus = value < 30;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: palette.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _StepButton(
            icon: Ionicons.remove,
            enabled: canMinus,
            onTap: canMinus ? () => onChange(-1) : null,
          ),
          SizedBox(
            width: 76,
            child: Text(
              '${value > 0 ? '+' : ''}$value $minutesLabel',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: value == 0 ? palette.textMuted : palette.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _StepButton(
            icon: Ionicons.add,
            enabled: canPlus,
            onTap: canPlus ? () => onChange(1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  bool _down = false;
  Timer? _repeat;

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  void _startRepeat() {
    if (widget.onTap == null) return;
    _repeat?.cancel();
    _repeat = Timer(const Duration(milliseconds: 380), () {
      _repeat = Timer.periodic(const Duration(milliseconds: 70), (_) {
        widget.onTap?.call();
      });
    });
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final disabled = !widget.enabled;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (!disabled) {
          setState(() => _down = true);
          _startRepeat();
        }
      },
      onTapCancel: () {
        setState(() => _down = false);
        _stopRepeat();
      },
      onTapUp: (_) {
        setState(() => _down = false);
        _stopRepeat();
      },
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationFast,
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled
              ? palette.surface2
              : (_down ? palette.surface3 : palette.surface2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.line),
        ),
        child: Icon(
          widget.icon,
          size: 16,
          color: disabled ? palette.textSubtle : palette.text,
        ),
      ),
    );
  }
}

