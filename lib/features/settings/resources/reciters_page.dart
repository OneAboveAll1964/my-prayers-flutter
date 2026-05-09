import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../core/i18n/app_l10n.dart';
import '../../../core/services/recitation_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/data/reciter_catalog.dart';
import '../../../shared/data/reciter_translations.dart';
import '../../../shared/state/recitation_provider.dart';
import '../../../shared/state/settings_provider.dart';
import '../../../shared/util/search.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_field.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_spinner.dart';
import '../../../shared/widgets/page_scaffold.dart';

class RecitersPage extends ConsumerStatefulWidget {
  const RecitersPage({super.key});
  @override
  ConsumerState<RecitersPage> createState() => _RecitersPageState();
}

enum _Filter { all, mujawwad, murattal, muallim }

class _RecitersPageState extends ConsumerState<RecitersPage> {
  String _query = '';
  _Filter _filter = _Filter.all;
  List<Reciter>? _reciters;
  String? _error;
  bool _loading = true;
  AudioPlayer? _samplePlayer;
  int? _samplePlaying;
  int? _sampleLoading;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _samplePlayer?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ReciterCatalog.all();
      if (!mounted) return;
      await ref
          .read(installedRecitersProvider.notifier)
          .refreshFor(list.map((r) => r.id));
      if (!mounted) return;
      setState(() {
        _reciters = list;
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

  Future<void> _toggleSample(Reciter reciter) async {
    if (_samplePlaying == reciter.id || _sampleLoading == reciter.id) {
      await _samplePlayer?.stop();
      if (mounted) {
        setState(() {
          _samplePlaying = null;
          _sampleLoading = null;
        });
      }
      return;
    }
    setState(() {
      _samplePlaying = null;
      _sampleLoading = reciter.id;
    });
    try {
      final url = await RecitationService.instance.sampleUrl(reciter.id);
      if (!mounted || _sampleLoading != reciter.id) return;
      _samplePlayer ??= AudioPlayer();
      await _samplePlayer!.stop();
      await _samplePlayer!.play(UrlSource(url));
      _samplePlayer!.onPlayerComplete.listen((_) {
        if (!mounted) return;
        if (_samplePlaying == reciter.id) {
          setState(() => _samplePlaying = null);
        }
      });
      if (!mounted) return;
      setState(() {
        _samplePlaying = reciter.id;
        _sampleLoading = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _samplePlaying = null;
        _sampleLoading = null;
      });
    }
  }

  Future<void> _stopSample() async {
    await _samplePlayer?.stop();
    if (mounted) {
      setState(() {
        _samplePlaying = null;
        _sampleLoading = null;
      });
    }
  }

  Future<void> _install(Reciter reciter) async {
    await _stopSample();
    if (!mounted) return;
    final l10n = AppL10n.of(context);
    final confirmed = await showAppSheet<bool>(
      context: context,
      title: '${l10n.t('reciters.install')} · ${localizedReciterName(reciter.id, reciter.name, langKey(l10n.locale))}',
      builder: (ctx) => _InstallConfirmBody(
        approxSizeMb: _approxSizeFor(reciter),
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await showAppSheet<bool>(
      context: context,
      title: l10n.t('reciters.installing'),
      builder: (ctx) => _InstallProgressBody(reciter: reciter),
      dismissible: false,
    );
    await ref
        .read(installedRecitersProvider.notifier)
        .refreshFor([reciter.id]);
    if (await RecitationService.instance.isInstalled(reciter.id)) {
      final settings = ref.read(settingsProvider);
      if (settings.selectedReciterId == null) {
        ref.read(settingsProvider.notifier).setSelectedReciter(reciter.id);
      }
    }
  }

  int _approxSizeFor(Reciter reciter) {
    final style = (reciter.style ?? '').toLowerCase();
    if (style.contains('mujawwad')) return 1500;
    if (style.contains('muallim')) return 700;
    return 700;
  }

  Future<void> _uninstall(Reciter reciter) async {
    await _stopSample();
    if (!mounted) return;
    final l10n = AppL10n.of(context);
    final confirmed = await showAppSheet<bool>(
      context: context,
      title: l10n.t('reciters.uninstallTitle'),
      builder: (ctx) => _UninstallConfirmBody(
        name: localizedReciterName(
            reciter.id, reciter.name, langKey(l10n.locale)),
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    if (confirmed != true) return;
    await RecitationService.instance.uninstall(reciter.id);
    await ref
        .read(installedRecitersProvider.notifier)
        .markUninstalled(reciter.id);
    final settings = ref.read(settingsProvider);
    if (settings.selectedReciterId == reciter.id) {
      ref.read(settingsProvider.notifier).setSelectedReciter(null);
    }
  }

  List<Reciter> _filtered() {
    final all = _reciters ?? const <Reciter>[];
    final q = _query.trim();
    return all.where((r) {
      final style = (r.style ?? '').toLowerCase();
      if (_filter == _Filter.mujawwad && !style.contains('mujawwad')) {
        return false;
      }
      if (_filter == _Filter.murattal && !style.contains('murattal')) {
        return false;
      }
      if (_filter == _Filter.muallim && !style.contains('muallim')) {
        return false;
      }
      if (q.isEmpty) return true;
      return matchesAny([
        r.name,
        r.translatedName,
        r.style ?? '',
        ...reciterNameVariants(r.id),
      ], q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = context.palette;
    final installed = ref.watch(installedRecitersProvider);
    final activeId = ref.watch(
        settingsProvider.select((s) => s.selectedReciterId));
    final filtered = _filtered();

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: l10n.t('resources.reciters'),
              back: true,
              search: AppTextField(
                hintText: l10n.t('reciters.search'),
                prefix: Icon(Ionicons.search_outline,
                    size: 18, color: palette.textMuted),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Text(
                l10n.t('reciters.selectActive'),
                style: TextStyle(
                  color: palette.textSubtle,
                  fontSize: 12,
                ),
              ),
            ),
            _FilterBar(
              current: _filter,
              onPick: (f) => setState(() => _filter = f),
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
                          itemBuilder: (ctx, i) => _ReciterTile(
                            reciter: filtered[i],
                            installed: installed.contains(filtered[i].id),
                            isActive: activeId == filtered[i].id,
                            isPlaying: _samplePlaying == filtered[i].id,
                            isLoadingSample: _sampleLoading == filtered[i].id,
                            onSampleTap: () => _toggleSample(filtered[i]),
                            onInstallTap: () => _install(filtered[i]),
                            onUninstallTap: () => _uninstall(filtered[i]),
                            onActivateTap: () => ref
                                .read(settingsProvider.notifier)
                                .setSelectedReciter(filtered[i].id),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onPick});
  final _Filter current;
  final ValueChanged<_Filter> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final entries = <(_Filter, String)>[
      (_Filter.all, l10n.t('reciters.filterAll')),
      (_Filter.murattal, l10n.t('reciters.styleMurattal')),
      (_Filter.mujawwad, l10n.t('reciters.styleMujawwad')),
      (_Filter.muallim, l10n.t('reciters.styleMuallim')),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: Row(
        children: [
          for (final (f, label) in entries) ...[
            _FilterChip(
              label: label,
              active: current == f,
              onTap: () => onPick(f),
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

class _ReciterTile extends StatelessWidget {
  const _ReciterTile({
    required this.reciter,
    required this.installed,
    required this.isActive,
    required this.isPlaying,
    required this.isLoadingSample,
    required this.onSampleTap,
    required this.onInstallTap,
    required this.onUninstallTap,
    required this.onActivateTap,
  });

  final Reciter reciter;
  final bool installed;
  final bool isActive;
  final bool isPlaying;
  final bool isLoadingSample;
  final VoidCallback onSampleTap;
  final VoidCallback onInstallTap;
  final VoidCallback onUninstallTap;
  final VoidCallback onActivateTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);
    final lang = langKey(l10n.locale);
    final localizedName =
        localizedReciterName(reciter.id, reciter.name, lang);
    final localizedStyle = localizedReciterStyle(reciter.style, lang);
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSampleTap,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isPlaying || isLoadingSample)
                      ? palette.accent
                      : palette.surface2,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: (isPlaying || isLoadingSample)
                          ? palette.accent
                          : palette.line),
                ),
                child: isLoadingSample
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.accentOn,
                        ),
                      )
                    : Icon(
                        isPlaying ? Ionicons.stop : Ionicons.play,
                        size: 16,
                        color: isPlaying ? palette.accentOn : palette.text,
                      ),
              ),
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
                  if (localizedStyle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        localizedStyle,
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
              label: installed
                  ? l10n.t('reciters.uninstall')
                  : l10n.t('reciters.install'),
              size: AppButtonSize.sm,
              variant: installed
                  ? AppButtonVariant.outline
                  : AppButtonVariant.solid,
              onPressed: installed ? onUninstallTap : onInstallTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _InstallConfirmBody extends StatelessWidget {
  const _InstallConfirmBody({
    required this.approxSizeMb,
    required this.onConfirm,
    required this.onCancel,
  });
  final int approxSizeMb;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n
                          .t('reciters.approxSize')
                          .replaceAll('{n}', '~$approxSizeMb'),
                      style: TextStyle(
                          color: palette.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.t('reciters.installNote'),
                      style:
                          TextStyle(color: palette.textMuted, fontSize: 12),
                    ),
                  ],
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

class _InstallProgressBody extends ConsumerStatefulWidget {
  const _InstallProgressBody({required this.reciter});
  final Reciter reciter;

  @override
  ConsumerState<_InstallProgressBody> createState() =>
      _InstallProgressBodyState();
}

class _InstallProgressBodyState extends ConsumerState<_InstallProgressBody> {
  StreamSubscription<RecitationProgress>? _sub;
  RecitationProgress? _progress;
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
    _sub = RecitationService.instance.install(widget.reciter.id).listen((p) {
      if (!mounted) return;
      setState(() {
        _progress = p;
        if (p.failed) {
          _failed = true;
          _error = p.errorMessage;
        } else if (p.isComplete) {
          _done = true;
          ref
              .read(installedRecitersProvider.notifier)
              .markInstalled(widget.reciter.id);
        }
      });
    });
  }

  Future<void> _cancel() async {
    await RecitationService.instance.cancelInstall(widget.reciter.id);
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
          l10n.t('reciters.installingBody'),
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.text, fontSize: 14),
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
