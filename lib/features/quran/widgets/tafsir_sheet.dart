import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/services/tafsir_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/data/tafsir_catalog.dart';
import '../../../shared/models/quran.dart';
import '../../../shared/state/settings_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_spinner.dart';

Future<void> showTafsirSheet({
  required BuildContext context,
  required Surah surah,
  required Ayah ayah,
}) {
  final l10n = AppL10n.of(context);
  final isEn = l10n.locale.languageCode == 'en';
  final surahName = isEn ? surah.englishName : surah.name;
  return showAppSheet<void>(
    context: context,
    title:
        '${l10n.t('quran.tafsir')} · $surahName ${ayah.numberInSurah}',
    builder: (sheetCtx) => _TafsirBody(surah: surah, ayah: ayah),
  );
}

class _TafsirBody extends ConsumerStatefulWidget {
  const _TafsirBody({required this.surah, required this.ayah});
  final Surah surah;
  final Ayah ayah;

  @override
  ConsumerState<_TafsirBody> createState() => _TafsirBodyState();
}

class _TafsirBodyState extends ConsumerState<_TafsirBody> {
  bool _loading = false;
  String? _text;
  String? _error;
  Tafsir? _tafsir;
  int? _loadedFor;

  @override
  void initState() {
    super.initState();
    final id = ref.read(settingsProvider).selectedTafsirId;
    if (id != null) _load(id);
  }

  Future<void> _load(int tafsirId) async {
    setState(() {
      _loading = true;
      _error = null;
      _loadedFor = tafsirId;
    });
    try {
      _tafsir ??= await _resolveTafsir(tafsirId);
      final raw = await TafsirService.instance.fetchAyahText(
        tafsirId,
        widget.surah.number,
        widget.ayah.numberInSurah,
      );
      if (!mounted) return;
      setState(() {
        _text = stripTafsirHtml(raw);
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

  Future<Tafsir?> _resolveTafsir(int id) async {
    final cached = TafsirCatalog.cachedAll();
    if (cached != null) {
      for (final t in cached) {
        if (t.id == id) return t;
      }
    }
    try {
      final list = await TafsirCatalog.all();
      for (final t in list) {
        if (t.id == id) return t;
      }
    } catch (_) {}
    return null;
  }

  void _openCatalog() {
    Navigator.of(context).pop();
    context.push('/settings/resources/tafsirs');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final activeId =
        ref.watch(settingsProvider.select((s) => s.selectedTafsirId));
    final trScale =
        ref.watch(settingsProvider.select((s) => s.translationFontScale));
    final bold = ref.watch(settingsProvider.select((s) => s.quranBold));

    if (activeId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Ionicons.book_outline, size: 28, color: palette.textMuted),
          const SizedBox(height: 10),
          Text(
            l10n.t('tafsirs.noneSelected'),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.text, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('tafsirs.noneSelectedBody'),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: palette.textMuted, fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: l10n.t('tafsirs.chooseTafsir'),
            variant: AppButtonVariant.solid,
            expand: true,
            onPressed: _openCatalog,
          ),
        ],
      );
    }

    if (_loadedFor != activeId) {
      _text = null;
      _tafsir = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _loadedFor != activeId) _load(activeId);
      });
    }

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: AppSpinner()),
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Ionicons.alert_circle_outline,
              size: 28, color: palette.textMuted),
          const SizedBox(height: 10),
          Text(
            l10n.t('common.error'),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.text, fontSize: 14),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.t('common.retry'),
            variant: AppButtonVariant.outline,
            expand: true,
            onPressed: () => _load(activeId),
          ),
        ],
      );
    }
    final isArabic = (_tafsir?.languageName.toLowerCase() ?? '') == 'arabic';
    final text = _text ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_tafsir != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _tafsir!.displaySubtitle,
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
            textDirection:
                isArabic ? TextDirection.rtl : Directionality.of(context),
            child: SelectableText(
              text.isEmpty ? l10n.t('tafsirs.empty') : text,
              style: TextStyle(
                color: palette.text,
                fontSize: 14.5 * trScale,
                height: 1.75,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
