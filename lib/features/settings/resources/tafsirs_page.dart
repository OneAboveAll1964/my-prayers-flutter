import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/services/tafsir_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/data/tafsir_catalog.dart';
import '../../../shared/state/settings_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_field.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_spinner.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../quran/widgets/tafsir_sheet.dart';

class TafsirsPage extends ConsumerStatefulWidget {
  const TafsirsPage({super.key});
  @override
  ConsumerState<TafsirsPage> createState() => _TafsirsPageState();
}

class _TafsirsPageState extends ConsumerState<TafsirsPage> {
  String _query = '';
  String _languageFilter = 'all';
  List<Tafsir>? _tafsirs;
  String? _error;
  bool _loading = true;
  final Set<int> _installed = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await TafsirCatalog.all();
      if (!mounted) return;
      final installed = <int>{};
      for (final t in list) {
        if (await TafsirService.instance.isInstalled(t.id)) {
          installed.add(t.id);
        }
      }
      if (!mounted) return;
      setState(() {
        _tafsirs = list;
        _installed
          ..clear()
          ..addAll(installed);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _install(Tafsir tafsir) async {
    final l10n = AppL10n.of(context);
    final ok = await showAppSheet<bool>(
      context: context,
      title: '${l10n.t('tafsirs.installTitle')} · ${tafsir.name}',
      builder: (ctx) => _InstallConfirmBody(
        languageLabel: tafsir.languageLabel,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    if (ok != true || !mounted) return;
    final done = await showAppSheet<bool>(
      context: context,
      title: l10n.t('tafsirs.installing'),
      dismissible: false,
      builder: (ctx) => _InstallProgressBody(tafsir: tafsir),
    );
    if (done == true && mounted) {
      setState(() => _installed.add(tafsir.id));
      final settings = ref.read(settingsProvider);
      if (settings.selectedTafsirId == null) {
        ref.read(settingsProvider.notifier).setSelectedTafsir(tafsir.id);
      }
    }
  }

  Future<void> _uninstall(Tafsir tafsir) async {
    final l10n = AppL10n.of(context);
    final ok = await showAppSheet<bool>(
      context: context,
      title: l10n.t('tafsirs.uninstallTitle'),
      builder: (ctx) => _UninstallConfirmBody(
        name: tafsir.name,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    if (ok != true || !mounted) return;
    await TafsirService.instance.uninstall(tafsir.id);
    if (!mounted) return;
    setState(() => _installed.remove(tafsir.id));
    final settings = ref.read(settingsProvider);
    if (settings.selectedTafsirId == tafsir.id) {
      ref.read(settingsProvider.notifier).setSelectedTafsir(null);
    }
  }

  Future<void> _showSample(Tafsir tafsir) async {
    final l10n = AppL10n.of(context);
    String? text;
    String? error;
    bool loading = true;
    await showAppSheet<void>(
      context: context,
      title: tafsir.name,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          if (loading && text == null && error == null) {
            TafsirService.instance
                .fetchAyahText(tafsir.id, 1, 1)
                .then((value) {
              if (!ctx.mounted) return;
              setSheetState(() {
                text = stripTafsirHtml(value);
                loading = false;
              });
            }).catchError((e) {
              if (!ctx.mounted) return;
              setSheetState(() {
                error = e.toString();
                loading = false;
              });
            });
          }
          final palette = ctx.palette;
          if (loading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: AppSpinner()),
            );
          }
          if (error != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Ionicons.alert_circle_outline,
                    color: palette.textMuted, size: 24),
                const SizedBox(height: 8),
                Text(
                  l10n.t('common.error'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.text, fontSize: 14),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: l10n.t('common.close'),
                  variant: AppButtonVariant.outline,
                  expand: true,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            );
          }
          final dir = tafsirTextDirection(tafsir.languageName, text);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${l10n.t('tafsirs.samplePrefix')} 1:1',
                  style: TextStyle(
                    color: palette.textSubtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  border: Border.all(color: palette.line),
                ),
                child: Directionality(
                  textDirection: dir,
                  child: Text(
                    text ?? '',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: l10n.t('common.close'),
                variant: AppButtonVariant.outline,
                expand: true,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _setActive(Tafsir tafsir) async {
    ref.read(settingsProvider.notifier).setSelectedTafsir(tafsir.id);
  }

  Set<String> _availableLanguages() {
    final all = _tafsirs ?? const <Tafsir>[];
    return all.map((t) => t.languageName).where((l) => l.isNotEmpty).toSet();
  }

  List<Tafsir> _filtered() {
    final all = _tafsirs ?? const <Tafsir>[];
    final q = _query.trim().toLowerCase();
    return all.where((t) {
      if (_languageFilter != 'all' && t.languageName != _languageFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return t.name.toLowerCase().contains(q) ||
          t.authorName.toLowerCase().contains(q) ||
          t.languageName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final activeId = ref.watch(
        settingsProvider.select((s) => s.selectedTafsirId));
    final filtered = _filtered();
    final languages = _availableLanguages().toList()..sort();

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: l10n.t('resources.tafsirs'),
              back: true,
              search: AppTextField(
                hintText: l10n.t('tafsirs.search'),
                prefix: Icon(Ionicons.search_outline,
                    size: 18, color: palette.textMuted),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text(
                l10n.t('tafsirs.selectActive'),
                style: TextStyle(
                  color: palette.textSubtle,
                  fontSize: 12,
                ),
              ),
            ),
            _LanguageFilterBar(
              current: _languageFilter,
              languages: languages,
              onPick: (v) => setState(() => _languageFilter = v),
            ),
            Expanded(
              child: _loading
                  ? const PageLoader()
                  : _error != null
                      ? _ErrorView(error: _error!, onRetry: _load)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _TafsirTile(
                            tafsir: filtered[i],
                            isActive: activeId == filtered[i].id,
                            isInstalled: _installed.contains(filtered[i].id),
                            onSampleTap: () => _showSample(filtered[i]),
                            onActivateTap: () => _setActive(filtered[i]),
                            onInstallTap: () => _install(filtered[i]),
                            onUninstallTap: () => _uninstall(filtered[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageFilterBar extends StatelessWidget {
  const _LanguageFilterBar({
    required this.current,
    required this.languages,
    required this.onPick,
  });
  final String current;
  final List<String> languages;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final entries = <(String, String)>[
      ('all', l10n.t('reciters.filterAll')),
      for (final lang in languages) (lang, localizedLanguageName(l10n, lang)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: Row(
        children: [
          for (final (key, label) in entries) ...[
            _FilterChip(
              label: label,
              active: current == key,
              onTap: () => onPick(key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? palette.accentSoft : palette.surface,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: active ? palette.accent : palette.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? palette.accentStrong : palette.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TafsirTile extends StatelessWidget {
  const _TafsirTile({
    required this.tafsir,
    required this.isActive,
    required this.isInstalled,
    required this.onSampleTap,
    required this.onActivateTap,
    required this.onInstallTap,
    required this.onUninstallTap,
  });
  final Tafsir tafsir;
  final bool isActive;
  final bool isInstalled;
  final VoidCallback onSampleTap;
  final VoidCallback onActivateTap;
  final VoidCallback onInstallTap;
  final VoidCallback onUninstallTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isActive ? null : onActivateTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? palette.accentSoft : palette.surface,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(
              color: isActive ? palette.accent : palette.line),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.line),
              ),
              child: Icon(Ionicons.book_outline,
                  size: 18, color: palette.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          tafsir.name,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l10n.t('reciters.active'),
                            style: TextStyle(
                              color: palette.accentOn,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (tafsir.displaySubtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        tafsir.displaySubtitle,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AppButton(
              label: l10n.t('tafsirs.sample'),
              size: AppButtonSize.sm,
              variant: AppButtonVariant.outline,
              onPressed: onSampleTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Ionicons.alert_circle_outline,
                size: 28, color: palette.textMuted),
            const SizedBox(height: 8),
            Text(
              l10n.t('common.error'),
              style: TextStyle(color: palette.text, fontSize: 14),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: l10n.t('common.retry'),
              variant: AppButtonVariant.outline,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
