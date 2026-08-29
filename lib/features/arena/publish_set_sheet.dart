import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/dealer/photo_state.dart';
import '../../core/sampler/moments.dart';
import '../widgets/photo_tile.dart';
import 'sets_providers.dart';

/// What to publish: a title, who may see it, and which of your Top photos.
class PublishChoice {
  const PublishChoice({required this.title, required this.visibility, required this.photoIds});
  final String title;
  final String visibility;
  final List<int> photoIds; // rank order
}

/// Pick photos from your ranking (one per moment, best first). The Top 10
/// starts selected; tap to add or remove, up to 50.
class PublishSetSheet extends ConsumerStatefulWidget {
  const PublishSetSheet({super.key, this.initialTitle, this.initialVisibility = 'friends', this.preselect = 10});
  final String? initialTitle;
  final String initialVisibility;
  final int preselect;

  static Future<PublishChoice?> show(BuildContext context, {String? title, String visibility = 'friends'}) => showModalBottomSheet<PublishChoice>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surface,
        builder: (_) => PublishSetSheet(initialTitle: title, initialVisibility: visibility),
      );

  @override
  ConsumerState<PublishSetSheet> createState() => _PublishSetSheetState();
}

class _PublishSetSheetState extends ConsumerState<PublishSetSheet> {
  late final TextEditingController _title = TextEditingController(text: widget.initialTitle ?? 'My top photos');
  late String _visibility = widget.initialVisibility;
  Set<int>? _picked;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(rankingProvider).value ?? const <PhotoState>[];
    final rated = onePerMoment(all.where((p) => p.observations > 0).toList(), keys: momentKeys(all)).take(50).toList();
    // Preselect the Top N once the ranking has actually arrived (the first
    // build can run before the stream emits).
    if (_picked == null && rated.isNotEmpty) _picked = {for (final p in rated.take(widget.preselect)) p.id};
    final picked = _picked ?? <int>{};
    final order = [for (final p in rated) if (picked.contains(p.id)) p.id];
    final busy = ref.watch(setsProvider).busy;
    final progress = ref.watch(setsProvider).progress;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      builder: (context, scroll) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Publish your Top ${order.length}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('Only the photos you tick leave your phone — downsized, location and camera data removed. Friends see them in your order and can rank them.', style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title', isDense: true), maxLength: 40),
            SegmentedButton<String>(
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(value: 'friends', label: Text('Friends'), icon: Icon(Icons.group_rounded, size: 16)),
                ButtonSegment(value: 'link', label: Text('Link'), icon: Icon(Icons.link_rounded, size: 16)),
                ButtonSegment(value: 'public', label: Text('Public'), icon: Icon(Icons.public_rounded, size: 16)),
              ],
              selected: {_visibility},
              onSelectionChanged: (v) => setState(() => _visibility = v.first),
            ),
            const SizedBox(height: 4),
            Text(
              switch (_visibility) {
                'friends' => 'Mutual follows only.',
                'link' => 'Friends, plus anyone you give the code to.',
                _ => 'Anyone on PhotoRank can find and rank it.',
              },
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ]),
        ),
        Expanded(
          child: rated.isEmpty
              ? const Center(child: Text('Rank some photos first.', style: TextStyle(color: Colors.white60)))
              : GridView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 6, crossAxisSpacing: 6),
                  itemCount: rated.length,
                  itemBuilder: (_, i) {
                    final p = rated[i];
                    final on = picked.contains(p.id);
                    final pos = order.indexOf(p.id);
                    return PhotoTile(
                      mediaId: p.mediaId,
                      size: ThumbCacheSizes.grid,
                      borderRadius: 12,
                      peekable: false,
                      onTap: () => setState(() {
                        if (on) {
                          picked.remove(p.id);
                        } else if (picked.length < 50) {
                          picked.add(p.id);
                        }
                      }),
                      child: Stack(children: [
                        if (!on) const ColoredBox(color: Colors.black54),
                        Positioned(
                          left: 6,
                          top: 6,
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: on ? AppTheme.accent : Colors.black45,
                            child: on ? Text('${pos + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black)) : const Icon(Icons.add, size: 14, color: Colors.white70),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              Expanded(child: Text(order.length < 3 ? 'Pick at least 3.' : '${order.length} photos, in your ranking order.', style: const TextStyle(color: Colors.white54, fontSize: 12))),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: busy || order.length < 3
                    ? null
                    : () => Navigator.pop(context, PublishChoice(title: _title.text.trim(), visibility: _visibility, photoIds: order)),
                icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.cloud_upload_rounded),
                label: Text(progress == null ? 'Publish' : '${progress.$1}/${progress.$2}'),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
