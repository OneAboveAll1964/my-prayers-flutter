import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/page_scaffold.dart';

class SettingsLanguagePage extends ConsumerWidget {
  const SettingsLanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final settings = ref.watch(settingsProvider);
    final entries = langDisplayNames.entries.toList();
    final active = settings.language ?? l10n.locale.languageCode;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l10n.t('settings.language'), back: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: [
                  AppSurface(
                    child: Column(
                      children: [
                        for (var i = 0; i < entries.length; i++) ...[
                          _LangRow(
                            code: entries[i].key,
                            label: entries[i].value,
                            selected: entries[i].key == active,
                            onTap: () {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setLanguage(entries[i].key);
                              context.pop();
                            },
                          ),
                          if (i < entries.length - 1)
                            Container(height: 1, color: palette.line),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangRow extends StatefulWidget {
  const _LangRow({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_LangRow> createState() => _LangRowState();
}

class _LangRowState extends State<_LangRow> {
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
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.selected)
              Icon(Icons.check_rounded, color: palette.accent, size: 20),
          ],
        ),
      ),
    );
  }
}
