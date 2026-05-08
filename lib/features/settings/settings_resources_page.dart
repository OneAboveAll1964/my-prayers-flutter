import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/reciter_catalog.dart';
import '../../shared/state/settings_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _reciters = ReciterCatalog.cachedAll();
    if (_reciters == null) {
      ReciterCatalog.all().then((list) {
        if (!mounted) return;
        setState(() => _reciters = list);
      }).catchError((_) {});
    }
  }

  String? _activeName(int? id) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final activeId =
        ref.watch(settingsProvider.select((s) => s.selectedReciterId));
    final activeLabel = _activeName(activeId) ?? '';

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
                          value: activeLabel,
                          onTap: () =>
                              context.push('/settings/resources/reciters'),
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
