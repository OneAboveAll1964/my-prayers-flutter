import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/i18n/app_l10n.dart';
import '../../../core/services/mushaf_asset_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_sheet.dart';

Future<bool> showMushafInstallSheet(BuildContext context) async {
  final l10n = AppL10n.of(context);
  final result = await showAppSheet<bool>(
    context: context,
    title: l10n.t('mushaf.installTitle'),
    builder: (sheetCtx) => const _MushafInstallBody(),
  );
  return result == true;
}

class _MushafInstallBody extends StatefulWidget {
  const _MushafInstallBody();

  @override
  State<_MushafInstallBody> createState() => _MushafInstallBodyState();
}

enum _Phase { intro, downloading, failed, done }

class _MushafInstallBodyState extends State<_MushafInstallBody> {
  StreamSubscription<MushafInstallProgress>? _sub;
  MushafInstallProgress? _progress;
  _Phase _phase = _Phase.intro;
  String? _error;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _phase = _Phase.downloading;
      _error = null;
    });
    _sub?.cancel();
    _sub =
        MushafAssetService.instance.install().listen((progress) {
      if (!mounted) return;
      setState(() {
        _progress = progress;
        if (progress.failed) {
          _phase = _Phase.failed;
          _error = progress.errorMessage;
        } else if (progress.isComplete) {
          _phase = _Phase.done;
        }
      });
    });
  }

  Future<void> _cancel() async {
    await MushafAssetService.instance.cancelInstall();
    if (mounted) Navigator.of(context).pop(false);
  }

  void _finish() {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = AppL10n.of(context);

    switch (_phase) {
      case _Phase.intro:
        return _IntroBody(
          palette: palette,
          l10n: l10n,
          onStart: _start,
          onCancel: () => Navigator.of(context).pop(false),
        );
      case _Phase.downloading:
        return _ProgressBody(
          palette: palette,
          l10n: l10n,
          progress: _progress,
          onCancel: _cancel,
        );
      case _Phase.failed:
        return _FailedBody(
          palette: palette,
          l10n: l10n,
          error: _error,
          onRetry: _start,
          onCancel: () => Navigator.of(context).pop(false),
        );
      case _Phase.done:
        return _DoneBody(
          palette: palette,
          l10n: l10n,
          onOpen: _finish,
        );
    }
  }
}

class _IntroBody extends StatelessWidget {
  const _IntroBody({
    required this.palette,
    required this.l10n,
    required this.onStart,
    required this.onCancel,
  });
  final dynamic palette;
  final AppL10n l10n;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(top: 4, bottom: 16),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Ionicons.book_outline,
              size: 30, color: palette.accentStrong),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              l10n.t('mushaf.installBody'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: l10n.t('mushaf.installAction'),
          variant: AppButtonVariant.solid,
          expand: true,
          onPressed: onStart,
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

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.palette,
    required this.l10n,
    required this.progress,
    required this.onCancel,
  });
  final dynamic palette;
  final AppL10n l10n;
  final MushafInstallProgress? progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final fontsDone = progress?.fontsDone ?? 0;
    final dataDone = progress?.dataDone ?? 0;
    final fontsTotal = progress?.totalFonts ?? 604;
    final dataTotal = progress?.totalData ?? 604;
    final fraction = progress?.fraction ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              l10n.t('mushaf.installing'),
              style: TextStyle(
                color: palette.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction == 0 ? null : fraction,
            minHeight: 8,
            backgroundColor: palette.surface2,
            valueColor:
                AlwaysStoppedAnimation<Color>(palette.accent),
          ),
        ),
        const SizedBox(height: 16),
        _ProgressRow(
          palette: palette,
          label: l10n.t('mushaf.installFonts'),
          done: fontsDone,
          total: fontsTotal,
        ),
        const SizedBox(height: 8),
        _ProgressRow(
          palette: palette,
          label: l10n.t('mushaf.installPages'),
          done: dataDone,
          total: dataTotal,
        ),
        const SizedBox(height: 24),
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

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.palette,
    required this.label,
    required this.done,
    required this.total,
  });
  final dynamic palette;
  final String label;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: palette.textMuted, fontSize: 13),
          ),
        ),
        Text(
          '$done / $total',
          style: TextStyle(
            color: palette.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _FailedBody extends StatelessWidget {
  const _FailedBody({
    required this.palette,
    required this.l10n,
    required this.error,
    required this.onRetry,
    required this.onCancel,
  });
  final dynamic palette;
  final AppL10n l10n;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(top: 4, bottom: 16),
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Ionicons.alert_circle_outline,
              size: 30, color: palette.textMuted),
        ),
        Text(
          l10n.t('mushaf.installFailed'),
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.text, fontSize: 14),
        ),
        if (error != null && error!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        AppButton(
          label: l10n.t('mushaf.installRetry'),
          variant: AppButtonVariant.solid,
          expand: true,
          onPressed: onRetry,
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

class _DoneBody extends StatelessWidget {
  const _DoneBody({
    required this.palette,
    required this.l10n,
    required this.onOpen,
  });
  final dynamic palette;
  final AppL10n l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(top: 4, bottom: 16),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Ionicons.checkmark_outline,
              size: 30, color: palette.accentStrong),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: l10n.t('mushaf.installDone'),
          variant: AppButtonVariant.solid,
          expand: true,
          onPressed: onOpen,
        ),
      ],
    );
  }
}
