import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/name_repository.dart';
import '../../shared/models/name_of_allah.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';

class NamesPage extends ConsumerStatefulWidget {
  const NamesPage({super.key});

  @override
  ConsumerState<NamesPage> createState() => _NamesPageState();
}

class _NamesPageState extends ConsumerState<NamesPage> {
  bool _loading = true;
  List<NameOfAllah> _names = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final l10n = AppL10n.of(context);
    final names = await NameOfAllahRepository.instance
        .getNames(langKey(l10n.locale));
    if (!mounted) return;
    setState(() {
      _names = names;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final settings = ref.watch(settingsProvider);
    final fontFamily = arabicFontFamilies[settings.arabicFont] ?? 'AmiriQuran';

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l10n.t('names.title'), back: true),
            Expanded(
              child: _loading
                  ? const PageLoader()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                      itemCount: _names.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.05,
                      ),
                      itemBuilder: (ctx, i) =>
                          _NameTile(name: _names[i], fontFamily: fontFamily),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameTile extends StatelessWidget {
  const _NameTile({required this.name, required this.fontFamily});
  final NameOfAllah name;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: palette.line),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${name.id}',
            style: TextStyle(
              color: palette.textSubtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Center(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                name.name,
                style: TextStyle(
                  color: palette.text,
                  fontFamily: fontFamily,
                  fontSize: 30,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (name.transliteration.isNotEmpty)
            Text(
              name.transliteration,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (name.translation.isNotEmpty)
            Text(
              name.translation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }
}
