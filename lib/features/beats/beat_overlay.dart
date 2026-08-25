import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme.dart';
import '../../core/beats/beat.dart';
import 'beat_pages.dart';

/// Stories-style container for a beat: progress dashes, tap to advance,
/// swipe down to skip, CTA / share / continue on the last page.
class BeatOverlay extends StatefulWidget {
  const BeatOverlay({
    super.key,
    required this.beat,
    required this.onContinue,
    this.onCta,
    this.onShared,
    this.continueLabel = 'Continue',
  });

  final Beat beat;
  final VoidCallback onContinue;
  final VoidCallback? onCta;
  final VoidCallback? onShared;
  final String continueLabel;

  @override
  State<BeatOverlay> createState() => _BeatOverlayState();
}

class _BeatOverlayState extends State<BeatOverlay> {
  int _page = 0;
  final _shareKey = GlobalKey();
  bool _sharing = false;

  bool get _last => _page >= widget.beat.pages.length - 1;

  void _next() {
    if (_last) {
      widget.onContinue();
    } else {
      HapticFeedback.selectionClick();
      setState(() => _page++);
    }
  }

  void _prev() {
    if (_page > 0) setState(() => _page--);
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/photorank-${widget.beat.kind.name}-${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Ranked with PhotoRank'));
      widget.onShared?.call();
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final beat = widget.beat;
    final cta = beat.cta;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) {
        final w = MediaQuery.sizeOf(context).width;
        if (d.localPosition.dx < w * 0.3) {
          _prev();
        } else {
          _next();
        }
      },
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 400) widget.onContinue();
      },
      child: ColoredBox(
        color: AppTheme.bg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  for (var i = 0; i < beat.pages.length; i++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= _page ? AppTheme.accent : Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < beat.pages.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
            Expanded(
              child: RepaintBoundary(
                key: _shareKey,
                child: ColoredBox(
                  color: AppTheme.bg,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(key: ValueKey(_page), child: BeatPageView(beat.pages[_page])),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  if (beat.shareable)
                    IconButton.filledTonal(
                      onPressed: _sharing ? null : _share,
                      icon: const Icon(Icons.ios_share_rounded),
                      tooltip: 'Share',
                    ),
                  if (beat.shareable) const SizedBox(width: 8),
                  if (cta != null && widget.onCta != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: widget.onCta,
                        child: Text(_ctaLabel(cta)),
                      ),
                    )
                  else
                    Expanded(
                      child: FilledButton(onPressed: widget.onContinue, child: Text(widget.continueLabel)),
                    ),
                  if (cta != null && widget.onCta != null) ...[
                    const SizedBox(width: 8),
                    TextButton(onPressed: widget.onContinue, child: const Text('Not now')),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ctaLabel(BeatCta cta) => switch (cta) {
        SettleDuelCta() => 'Settle it',
        VibeCheckCta() => 'Still feeling it?',
        TryModeCta() => 'Try it now',
        ThemedDeckCta() => 'Deal it',
      };
}
