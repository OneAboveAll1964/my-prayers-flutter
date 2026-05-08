import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/services/surah_name_font_service.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/reciter_catalog.dart';
import '../../shared/data/tafsir_catalog.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_sheet.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';
import 'widgets/settings_widgets.dart';

class SettingsResourcesPage extends ConsumerStatefulWidget {
  const SettingsResourcesPage({super.key});

  @override
  ConsumerState<SettingsResourcesPage> createState() =>
      _SettingsResourcesPageState();
}

class _SettingsResourcesPageState
    extends ConsumerState<SettingsResourcesPage> {
  List<Reciter>? _reciters;
  List<Tafsir>? _tafsirs;

  @override
  void initState() {
    super.initState();
    _reciters = ReciterCatalog.cachedAll();
    _tafsirs = TafsirCatalog.cachedAll();
    if (_reciters == null) {
      ReciterCatalog.all().then((list) {
        if (!mounted) return;
        setState(() => _reciters = list);
      }).catchError((_) {});
    }
    if (_tafsirs == null) {
      TafsirCatalog.all().then((list) {
        if (!mounted) return;
        setState(() => _tafsirs = list);
      }).catchError((_) {});
    }
  }

  String? _activeReciterName(int? id) {
    if (id == null) return null;
    final list = _reciters;
    if (list == null) return null;
    for (final r in list) {
      if (r.id == id) {
        final style = r.style ?? '';
        return style.isEmpty ? r.name : '${r.name} · $style';
      }
    }
    return null;
  }

  String? _activeTafsirName(int? id) {
    if (id == null) return null;
    final list = _tafsirs;
    if (list == null) return null;
    for (final t in list) {
      if (t.id == id) return t.name;
    }
    return null;
  }

  Future<void> _toggleSurahFont() async {
    final svc = SurahNameFontService.instance;
    final l10n = AppL10n.of(context);
    if (svc.ready.value) {
      await svc.uninstall();
      return;
    }
    if (!mounted) return;
    await showAppSheet<void>(
      context: context,
      title: l10n.t('resources.surahNameFont'),
      dismissible: false,
      builder: (ctx) => const _SurahFontInstallBody(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final activeReciterId =
        ref.watch(settingsProvider.select((s) => s.selectedReciterId));
    final activeTafsirId =
        ref.watch(settingsProvider.select((s) => s.selectedTafsirId));
    final reciterLabel = _activeReciterName(activeReciterId) ?? '';
    final tafsirLabel = _activeTafsirName(activeTafsirId) ?? '';

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l10n.t('resources.title'), back: true),
            Expanded(
              child: PageBody(
                children: [
                  AppSurface(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SettingsTile(
                          icon: Ionicons.musical_notes_outline,
                          label: l10n.t('resources.reciters'),
                          value: reciterLabel,
                          onTap: () =>
                              context.push('/settings/resources/reciters'),
                        ),
                        const SettingsDivider(),
                        SettingsTile(
                          icon: Ionicons.book_outline,
                          label: l10n.t('resources.tafsirs'),
                          value: tafsirLabel,
                          onTap: () =>
                              context.push('/settings/resources/tafsirs'),
                        ),
                        const SettingsDivider(),
                        SettingsTile(
                          icon: Ionicons.information_circle_outline,
                          label: l10n.t('resources.surahInfo'),
                          value: '',
                          onTap: () =>
                              context.push('/settings/resources/surah-info'),
                        ),
                        const SettingsDivider(),
                        ValueListenableBuilder<bool>(
                          valueListenable:
                              SurahNameFontService.instance.ready,
                          builder: (ctx, ready, _) {
                            return SettingsTile(
                              icon: Ionicons.text_outline,
                              label: l10n.t('resources.surahNameFont'),
                              value: ready
                                  ? l10n.t('reciters.installed')
                                  : '',
                              onTap: _toggleSurahFont,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Text(
                      l10n.t('resources.description'),
                      style: TextStyle(
                        color: palette.textSubtle,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
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

class _SurahFontInstallBody extends StatefulWidget {
  const _SurahFontInstallBody();
  @override
  State<_SurahFontInstallBody> createState() => _SurahFontInstallBodyState();
}

class _SurahFontInstallBodyState extends State<_SurahFontInstallBody> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await SurahNameFontService.instance.install();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: AppSpinner()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Ionicons.alert_circle_outline,
            size: 28, color: palette.textMuted),
        const SizedBox(height: 8),
        Text(
          _error ?? l10n.t('common.error'),
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: l10n.t('common.retry'),
          variant: AppButtonVariant.solid,
          expand: true,
          onPressed: _start,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: l10n.t('common.cancel'),
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
