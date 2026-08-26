import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart' show isDesktop;

import '../../app/theme.dart';

/// Shows exactly what will be shared, then renders it to a PNG.
class SharePreviewScreen extends StatefulWidget {
  const SharePreviewScreen({super.key, required this.card, required this.filename, this.text = 'Ranked with PhotoRank'});

  final Widget card;
  final String filename;
  final String text;

  static Future<void> open(BuildContext context, {required Widget card, required String filename, String? text}) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => SharePreviewScreen(card: card, filename: filename, text: text ?? 'Ranked with PhotoRank'),
      ));

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  final _key = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (isDesktop) {
        final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/${widget.filename}');
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.filename}');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: widget.text));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C21),
      appBar: AppBar(backgroundColor: const Color(0xFF1C1C21), title: const Text('Share')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: RepaintBoundary(key: _key, child: widget.card),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: FilledButton.icon(
              onPressed: _busy ? null : _share,
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(_busy ? 'Rendering…' : 'Share image'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
