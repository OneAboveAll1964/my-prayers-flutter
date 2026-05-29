import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Wraps [child] and transitions between content with a symmetric
/// stretch-and-blur: the old content un-forms (stretches horizontally, blurs
/// and fades out) and the new content forms by the exact reverse.
///
/// Give this a FIXED size (e.g. a [SizedBox]) so swapping content of a
/// different size never shifts the surrounding layout. Re-triggerable
/// mid-animation — it snapshots the current content and restarts.
///
/// ```
/// await snapKey.currentState!.prepare(); // snapshot the old child
/// changeSomething();                     // child rebuilds with new content
/// snapKey.currentState!.play();          // old un-forms, new forms in reverse
/// ```
class SnapDissolve extends StatefulWidget {
  const SnapDissolve({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 380),
  });

  final Widget child;
  final Duration duration;

  @override
  State<SnapDissolve> createState() => SnapDissolveState();
}

class SnapDissolveState extends State<SnapDissolve>
    with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  ui.Image? _snapshot;
  Size _snapSize = Size.zero;
  bool _playing = false;

  /// Snapshots the currently-rendered child (call before changing it). Works
  /// mid-animation: the boundary wraps the raw child, so the capture is always
  /// the crisp, full-opacity content regardless of any in-flight transform.
  Future<void> prepare() async {
    try {
      final obj = _key.currentContext?.findRenderObject();
      if (obj is! RenderRepaintBoundary) return;
      final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 2.0);
      final img = await obj.toImage(pixelRatio: dpr);
      _snapshot?.dispose();
      _snapshot = img;
      _snapSize = obj.size;
    } catch (_) {
      _snapshot = null;
    }
  }

  /// Plays the transition over the (already updated) child. Restartable.
  void play() {
    if (_snapshot == null) return;
    _playing = true;
    _c.forward(from: 0).whenComplete(() {
      if (!mounted || _c.value < 1) return; // restarts orphan the prior run
      setState(() => _playing = false);
      _snapshot?.dispose();
      _snapshot = null;
    });
    setState(() {});
  }

  bool get isBusy => _playing;

  /// The shared form transform. [p] = 1 is fully formed (sharp), [p] = 0 is
  /// fully un-formed (stretched wide, blurred, transparent).
  Widget _formed(Widget child, double p) {
    final q = p.clamp(0.0, 1.0);
    return Opacity(
      opacity: q,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: (1 - q) * 9, sigmaY: 0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(1 + (1 - q) * 0.12, 1, 1),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Live (new) content — forms in over the second half (p: 0 → 1).
        Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final boundary = RepaintBoundary(key: _key, child: widget.child);
              if (!_playing) return boundary;
              final f = Curves.easeInOut
                  .transform(((_c.value - 0.5) / 0.5).clamp(0.0, 1.0));
              return _formed(boundary, f);
            },
          ),
        ),
        // Old content — un-forms over the first half (the exact reverse, p: 1 → 0).
        if (_playing && _snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final o = Curves.easeInOut
                        .transform((_c.value / 0.5).clamp(0.0, 1.0));
                    if (o >= 1) return const SizedBox.shrink();
                    return _formed(
                      RawImage(
                        image: _snapshot,
                        width: _snapSize.width,
                        height: _snapSize.height,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.low,
                      ),
                      1 - o,
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
