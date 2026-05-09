import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/services/surah_info_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/state/settings_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_spinner.dart';
import '../../../shared/widgets/page_scaffold.dart';
import '../../quran/widgets/surah_info_sheet.dart';

class SurahInfoLanguagesPage extends ConsumerStatefulWidget {
  const SurahInfoLanguagesPage({super.key});
  @override
  ConsumerState<SurahInfoLanguagesPage> createState() =>
      _SurahInfoLanguagesPageState();
}

class _SurahInfoLanguagesPageState
    extends ConsumerState<SurahInfoLanguagesPage> {
  final Set<String> _installed = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final found = <String>{};
    for (final lang in supportedSurahInfoLanguages()) {
      if (await SurahInfoService.instance.isInstalled(lang)) {
        found.add(lang);
      }
    }
    if (!mounted) return;
    setState(() {
      _installed
        ..clear()
        ..addAll(found);
      _loading = false;
    });
  }

  Future<void> _install(String lang) async {
    final l10n = AppL10n.of(context);
    final ok = await showAppSheet<bool>(
      context: context,
      title: '${l10n.t('surahInfo.installTitle')} · ${localizedLanguageName(l10n, lang)}',
      dismissible: false,
      builder: (ctx) => _InstallProgressBody(lang: lang),
    );
    if (ok == true) {
      await _refresh();
      final settings = ref.read(settingsProvider);
      if (settings.selectedSurahInfoLanguage == null) {
        ref
            .read(settingsProvider.notifier)
            .setSelectedSurahInfoLanguage(lang);
      }
    }
  }

  Future<void> _uninstall(String lang) async {
    await SurahInfoService.instance.uninstall(lang);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final langs = supportedSurahInfoLanguages();
    final activeLang = ref
        .watch(settingsProvider.select((s) => s.selectedSurahInfoLanguage));

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l10n.t('resources.surahInfo'), back: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                l10n.t('surahInfo.description'),
                style: TextStyle(
                  color: palette.textSubtle,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
              child: Text(
                l10n.t('surahInfo.selectActive'),
                style: TextStyle(
                  color: palette.textSubtle,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const PageLoader()
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                itemCount: langs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final lang = langs[i];
                  final installed = _installed.contains(lang);
                  final active = activeLang == lang;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: active
                        ? null
                        : () => ref
                            .read(settingsProvider.notifier)
                            .setSelectedSurahInfoLanguage(lang),
                    child: Container(
                      decoration: BoxDecoration(
                        color: active ? palette.accentSoft : palette.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radius),
                        border: Border.all(
                            color:
                                active ? palette.accent : palette.line),
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
                            child: Icon(Ionicons.information_circle_outline,
                                size: 18, color: palette.textMuted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    localizedLanguageName(l10n, lang),
                                    style: TextStyle(
                                      color: palette.text,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (active) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: palette.accent,
                                      borderRadius:
                                          BorderRadius.circular(999),
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
                          ),
                          const SizedBox(width: 10),
                          AppButton(
                            label: installed
                                ? l10n.t('reciters.uninstall')
                                : l10n.t('reciters.install'),
                            size: AppButtonSize.sm,
                            variant: installed
                                ? AppButtonVariant.outline
                                : AppButtonVariant.solid,
                            onPressed: installed
                                ? () => _uninstall(lang)
                                : () => _install(lang),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallProgressBody extends StatefulWidget {
  const _InstallProgressBody({required this.lang});
  final String lang;

  @override
  State<_InstallProgressBody> createState() => _InstallProgressBodyState();
}

class _InstallProgressBodyState extends State<_InstallProgressBody> {
  StreamSubscription<SurahInfoProgress>? _sub;
  SurahInfoProgress? _progress;
  bool _failed = false;
  String? _error;

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
    });
    _sub?.cancel();
    _sub = SurahInfoService.instance.install(widget.lang).listen((p) {
      if (!mounted) return;
      setState(() {
        _progress = p;
        if (p.failed) {
          _failed = true;
          _error = p.errorMessage;
        }
      });
      if (p.isComplete) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> _cancel() async {
    await SurahInfoService.instance.cancelInstall(widget.lang);
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final p = _progress;
    final fraction = p?.fraction ?? 0.0;
    final done = p?.filesDone ?? 0;
    final total = p?.totalFiles ?? 114;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.t('surahInfo.installingBody'),
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
