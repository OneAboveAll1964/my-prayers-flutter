import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/hijri.dart';
import '../../shared/data/prayer_time_repository.dart';
import '../../shared/models/prayer_time.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';
import 'widgets/date_bar.dart';
import 'widgets/last_read_card.dart';
import 'widgets/location_bar.dart';
import 'widgets/next_prayer_countdown.dart';
import 'widgets/prayer_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  PrayerTime? _prayer;
  bool _loading = false;
  late DateTime _date;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayer() async {
    final s = ref.read(settingsProvider);
    if (s.location == null) {
      setState(() => _prayer = null);
      return;
    }
    setState(() => _loading = true);
    final result = await PrayerTimeRepository.instance.getPrayerTimes(
      location: s.location!,
      date: _date,
      attribute: s.toAttribute(),
      useFixedPrayer: s.useFixedTimes,
    );
    if (!mounted) return;
    setState(() {
      _prayer = result;
      _loading = false;
    });
  }

  int _findCurrentIndex(PrayerTime? p) {
    if (p == null) return -1;
    final now = DateTime.now();
    final arr = p.all;
    var i = -1;
    for (var j = 0; j < arr.length; j++) {
      if (!arr[j].isAfter(now)) i = j;
    }
    return i;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final favorites = ref.watch(favoritesProvider);
    final l10n = AppL10n.of(context);
    final palette = context.palette;

    ref.listen(settingsProvider, (prev, next) {
      if (prev?.location != next.location ||
          prev?.useFixedTimes != next.useFixedTimes ||
          prev?.calculationMethod != next.calculationMethod ||
          prev?.asrMethod != next.asrMethod ||
          prev?.higherLatitudeMethod != next.higherLatitudeMethod ||
          prev?.fajrAngle != next.fajrAngle ||
          prev?.ishaAngle != next.ishaAngle ||
          !_listsEqual(prev?.offsets, next.offsets)) {
        _loadPrayer();
      }
    });

    if (_prayer == null && !_loading && settings.location != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrayer());
    }

    final idx = _findCurrentIndex(_prayer);

    return Column(
      children: [
        PageHeader(
          title: l10n.t('appName'),
          action: settings.location == null
              ? null
              : LocationBar(name: settings.location!.name),
        ),
        Expanded(
          child: PageBody(
            children: [
              DateBar(
                gregorian: _date,
                hijri: formatHijri(
                    _date,
                    settings.language?.startsWith('ar') == true ? 'ar' : 'en'),
              ),
              if (settings.location == null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    border: Border.all(color: palette.line),
                    borderRadius: BorderRadius.circular(AppTokens.radius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('home.noLocation'),
                        style: TextStyle(color: palette.textMuted),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: l10n.t('home.searchCity'),
                        onPressed: () => context.push('/settings/location'),
                      ),
                    ],
                  ),
                )
              else if (_loading && _prayer == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: AppSpinner()),
                )
              else if (_prayer != null) ...[
                NextPrayerCountdown(
                  prayer: _prayer!,
                  language: settings.language ??
                      Localizations.localeOf(context).languageCode,
                ),
                PrayerCard(
                  prayer: _prayer!,
                  currentIndex: idx,
                  language: settings.language ??
                      Localizations.localeOf(context).languageCode,
                ),
              ],
              if (favorites.lastSurah != null)
                LastReadCard(entry: favorites.lastSurah!),
            ],
          ),
        ),
      ],
    );
  }

  bool _listsEqual(List<int>? a, List<int>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

String dayNameLocalised(DateTime d, String lang) {
  return DateFormat.EEEE(_intlLocale(lang)).format(d);
}

String _intlLocale(String code) {
  if (code == 'ckb' || code == 'ckb_Badini') return 'ar';
  return code;
}
