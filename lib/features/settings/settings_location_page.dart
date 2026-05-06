import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_l10n.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/tokens.dart';
import '../../shared/data/location_repository.dart';
import '../../shared/models/location.dart';
import '../../shared/state/favorites_provider.dart';
import '../../shared/state/settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_field.dart';
import '../../shared/widgets/app_spinner.dart';
import '../../shared/widgets/page_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsLocationPage extends ConsumerStatefulWidget {
  const SettingsLocationPage({super.key});

  @override
  ConsumerState<SettingsLocationPage> createState() =>
      _SettingsLocationPageState();
}

class _SettingsLocationPageState extends ConsumerState<SettingsLocationPage> {
  Timer? _debounce;
  String _query = '';
  List<AppLocation> _results = [];
  bool _searching = false;
  bool _detecting = false;

  Future<void> _runSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final list = await LocationRepository.instance.search(q, limit: 25);
    if (!mounted) return;
    setState(() {
      _results = list;
      _searching = false;
    });
  }

  Future<void> _detect() async {
    setState(() => _detecting = true);
    try {
      final perm = await Geolocator.checkPermission();
      var allowed = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      if (!allowed) {
        final req = await Geolocator.requestPermission();
        allowed = req == LocationPermission.always ||
            req == LocationPermission.whileInUse;
      }
      if (!allowed) {
        if (mounted) setState(() => _detecting = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium));
      final found = await LocationRepository.instance
          .reverseGeocode(pos.latitude, pos.longitude);
      if (!mounted) return;
      if (found != null) {
        _select(found);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  void _select(AppLocation loc) {
    ref.read(settingsProvider.notifier).setLocation(loc);
    ref.read(favoritesProvider.notifier).pushRecentLocation(loc);
    final s = ref.read(settingsProvider);
    NotificationService.instance.reschedule(
      location: loc,
      attribute: s.toAttribute(),
      useFixed: s.useFixedTimes,
      enabled: s.notificationsEnabled,
      perPrayer: s.perPrayerNotifications,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final fav = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: l10n.t('settings.location'),
              back: true,
              search: AppTextField(
                hintText: l10n.t('home.searchCity'),
                prefix: Icon(LucideIcons.search,
                    size: 18, color: palette.textMuted),
                onChanged: (v) {
                  _query = v;
                  _debounce?.cancel();
                  _debounce = Timer(
                      const Duration(milliseconds: 220), () => _runSearch(v));
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  const SizedBox(height: 6),
                  AppButton(
                    label: _detecting
                        ? l10n.t('common.loading')
                        : l10n.t('home.useMyLocation'),
                    icon: _detecting ? null : LucideIcons.locateFixed,
                    expand: true,
                    variant: AppButtonVariant.outline,
                    onPressed: _detecting ? null : _detect,
                  ),
                  if (_query.trim().isEmpty && fav.recentLocations.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionLabel(label: l10n.t('favorites.recentLocations')),
                    const SizedBox(height: 6),
                    AppSurface(
                      child: Column(
                        children: [
                          for (var i = 0; i < fav.recentLocations.length; i++) ...[
                            _LocationRow(
                              location: fav.recentLocations[i],
                              onTap: () => _select(fav.recentLocations[i]),
                            ),
                            if (i < fav.recentLocations.length - 1)
                              Container(height: 1, color: palette.line),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (_query.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    if (_searching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: AppSpinner(size: 22)),
                      )
                    else if (_results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.t('common.noResults'),
                            style: TextStyle(color: palette.textMuted)),
                      )
                    else
                      AppSurface(
                        child: Column(
                          children: [
                            for (var i = 0; i < _results.length; i++) ...[
                              _LocationRow(
                                location: _results[i],
                                onTap: () => _select(_results[i]),
                              ),
                              if (i < _results.length - 1)
                                Container(height: 1, color: palette.line),
                            ],
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label,
          style: TextStyle(
              color: context.palette.textSubtle,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4)),
    );
  }
}

class _LocationRow extends StatefulWidget {
  const _LocationRow({required this.location, required this.onTap});
  final AppLocation location;
  final VoidCallback onTap;

  @override
  State<_LocationRow> createState() => _LocationRowState();
}

class _LocationRowState extends State<_LocationRow> {
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Icon(LucideIcons.mapPin,
                  size: 14, color: palette.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.location.name,
                      style: TextStyle(
                          color: palette.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600)),
                  if (widget.location.countryName.isNotEmpty)
                    Text(widget.location.countryName,
                        style: TextStyle(
                            color: palette.textSubtle, fontSize: 12)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 18, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}
