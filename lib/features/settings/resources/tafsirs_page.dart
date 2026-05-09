import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/services/tafsir_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/data/tafsir_catalog.dart';
import '../../../shared/data/tafsir_translations.dart';
import '../../../shared/state/settings_provider.dart';
import '../../../shared/util/search.dart';
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
    final lang = langKey(l10n.locale);
    final localizedName =
        localizedTafsirName(tafsir.id, tafsir.name, lang);
    final ok = await showAppSheet<bool>(
      context: context,
      title: '${l10n.t('tafsirs.installTitle')} · $localizedName',
      builder: (ctx) => _InstallConfirmBody(
        languageLabel: localizedLanguageName(l10n, tafsir.languageName),
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
        name: localizedTafsirName(
            tafsir.id, tafsir.name, langKey(l10n.locale)),
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
    final lang = langKey(l10n.locale);
    final localizedName = localizedTafsirName(tafsir.id, tafsir.name, lang);
    String? text;
    String? error;
    bool loading = true;
    await showAppSheet<void>(
      context: context,
      title: localizedName,
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
    final q = _query.trim();
    return all.where((t) {
      if (_languageFilter != 'all' && t.languageName != _languageFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return matchesAny([
        t.name,
        t.authorName,
        t.languageName,
        ...tafsirNameVariants(t.id),
      ], q);
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
    final lang = langKey(l10n.locale);
    final localizedName =
        localizedTafsirName(tafsir.id, tafsir.name, lang);
    final localizedLanguage =
        localizedLanguageName(l10n, tafsir.languageName);
    final subtitleParts = <String>[
      if (localizedLanguage.isNotEmpty) localizedLanguage,
      if (tafsir.authorName.isNotEmpty) tafsir.authorName,
    ];
    final subtitle = subtitleParts.join(' · ');
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
                          localizedName,
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
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
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
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSampleTap,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.surface2,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.line),
                ),
                child: Icon(Ionicons.eye_outline,
                    size: 16, color: palette.text),
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: isInstalled
                  ? l10n.t('reciters.uninstall')
                  : l10n.t('reciters.install'),
              size: AppButtonSize.sm,
              variant: isInstalled
                  ? AppButtonVariant.outline
                  : AppButtonVariant.solid,
              onPressed: isInstalled ? onUninstallTap : onInstallTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallConfirmBody extends StatelessWidget {
  const _InstallConfirmBody({
    required this.languageLabel,
    required this.onConfirm,
    required this.onCancel,
  });
  final String languageLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            border: Border.all(color: palette.line),
          ),
          child: Row(
            children: [
              Icon(Ionicons.cloud_download_outline,
                  size: 22, color: palette.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.t('tafsirs.installNote'),
                  style: TextStyle(color: palette.text, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: l10n.t('reciters.install'),
          variant: AppButtonVariant.solid,
          expand: true,
          onPressed: onConfirm,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: l10n.t('common.cancel'),
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: onCancel,
        ),
      ],
    );
  }
}

class _UninstallConfirmBody extends StatelessWidget {
  const _UninstallConfirmBody({
    required this.name,
    required this.onConfirm,
    required this.onCancel,
  });
  final String name;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            l10n.t('reciters.uninstallBody').replaceAll('{name}', name),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: palette.textMuted, fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: l10n.t('reciters.uninstall'),
          variant: AppButtonVariant.danger,
          expand: true,
          onPressed: onConfirm,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: l10n.t('common.cancel'),
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: onCancel,
        ),
      ],
    );
  }
}

class _InstallProgressBody extends StatefulWidget {
  const _InstallProgressBody({required this.tafsir});
  final Tafsir tafsir;

  @override
  State<_InstallProgressBody> createState() => _InstallProgressBodyState();
}

class _InstallProgressBodyState extends State<_InstallProgressBody> {
  StreamSubscription<TafsirProgress>? _sub;
  TafsirProgress? _progress;
  bool _failed = false;
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _failed = false;
      _error = null;
      _done = false;
    });
    _sub?.cancel();
    _sub = TafsirService.instance.install(widget.tafsir.id).listen((p) {
      if (!mounted) return;
      setState(() {
        _progress = p;
        if (p.failed) {
          _failed = true;
          _error = p.errorMessage;
        } else if (p.isComplete) {
          _done = true;
        }
      });
    });
  }

  Future<void> _cancel() async {
    await TafsirService.instance.cancelInstall(widget.tafsir.id);
    if (mounted) Navigator.of(context).pop(false);
  }

  void _close() => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final p = _progress;
    final fraction = p?.fraction ?? 0.0;
    final done = p?.filesDone ?? 0;
    final total = p?.totalFiles ?? 6236;

    if (_failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Ionicons.alert_circle_outline,
              size: 28, color: palette.textMuted),
          const SizedBox(height: 8),
          Text(
            l10n.t('reciters.installFailed'),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.text, fontSize: 14),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: l10n.t('mushaf.installRetry'),
            variant: AppButtonVariant.solid,
            expand: true,
            onPressed: _start,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: l10n.t('common.cancel'),
            variant: AppButtonVariant.outline,
            expand: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      );
    }

    if (_done) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Ionicons.checkmark_circle, size: 28, color: palette.accent),
          const SizedBox(height: 12),
          Text(
            l10n.t('reciters.installComplete'),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.text, fontSize: 14),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.t('common.done'),
            variant: AppButtonVariant.solid,
            expand: true,
            onPressed: _close,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('tafsirs.installingBody'),
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.text, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction == 0 ? null : fraction,
            minHeight: 8,
            backgroundColor: palette.surface2,
            valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$done / $total',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 12.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 18),
        AppButton(
          label: l10n.t('common.cancel'),
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: _cancel,
        ),
      ],
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
