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

const _supportedSurahInfoLanguages = <String>[
  'english',
  'arabic',
  'urdu',
  'bengali',
  'indonesian',
  'russian',
  'turkish',
  'persian',
  'french',
  'german',
  'spanish',
  'portuguese',
  'chinese',
  'malay',
];

const Map<String, String> _appLangToInfoLang = {
  'en': 'english',
  'ar': 'arabic',
  'ckb': 'arabic',
  'ckb_Badini': 'arabic',
};

String surahInfoLanguageFor(AppL10n l10n) {
  return _appLangToInfoLang[langKey(l10n.locale)] ?? 'english';
}

List<String> supportedSurahInfoLanguages() => _supportedSurahInfoLanguages;

Future<void> showSurahInfoSheet({
  required BuildContext context,
  required int surahNumber,
  required String displayName,
}) {
  final l10n = AppL10n.of(context);
  return showAppSheet<void>(
    context: context,
    title: '${l10n.t('surahInfo.title')} · $displayName',
    builder: (sheetCtx) => _SurahInfoBody(surahNumber: surahNumber),
  );
}

class _SurahInfoBody extends ConsumerStatefulWidget {
  const _SurahInfoBody({required this.surahNumber});
  final int surahNumber;

  @override
  ConsumerState<_SurahInfoBody> createState() => _SurahInfoBodyState();
}

class _SurahInfoBodyState extends ConsumerState<_SurahInfoBody> {
  bool _loading = true;
  String? _text;
  String _source = '';
  String? _error;
  String? _loadedLang;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final lang = surahInfoLanguageFor(AppL10n.of(context));
    setState(() {
      _loading = true;
      _error = null;
      _loadedLang = lang;
    });
    try {
      final info =
          await SurahInfoService.instance.fetch(widget.surahNumber, lang);
      if (!mounted) return;
      setState(() {
        _text = stripSurahInfoHtml(info.text);
        _source = info.source;
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final lang = surahInfoLanguageFor(l10n);
    final trScale =
        ref.watch(settingsProvider.select((s) => s.translationFontScale));
    final bold = ref.watch(settingsProvider.select((s) => s.quranBold));

    if (_loadedLang != null && _loadedLang != lang && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
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
            onPressed: _load,
          ),
        ],
      );
    }

    final isArabic = lang == 'arabic';
    final text = _text ?? '';
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
          child: Directionality(
            textDirection:
                isArabic ? TextDirection.rtl : Directionality.of(context),
            child: SelectableText(
              text.isEmpty ? l10n.t('surahInfo.empty') : text,
              style: TextStyle(
                color: palette.text,
                fontSize: 14.5 * trScale,
                height: 1.75,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ),
        if (_source.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _source,
              style: TextStyle(
                color: palette.textSubtle,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
