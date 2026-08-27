import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/sampler/moments.dart';
import '../../data/arena/arena_models.dart';
import '../widgets/photo_tile.dart';
import 'arena_image.dart';
import 'arena_providers.dart';
import 'arena_rounds_screen.dart';
import 'arena_profile_screen.dart';

/// The Arena tab: today's entry, a round of rating, and the live board.
class ArenaScreen extends ConsumerStatefulWidget {
  const ArenaScreen({super.key});

  @override
  ConsumerState<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends ConsumerState<ArenaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(arenaProvider).profile == null) ref.read(arenaProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(arenaProvider);
    final ctl = ref.read(arenaProvider.notifier);
    ref.listen(arenaProvider.select((s) => s.error), (_, err) {
      if (err != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    });
    final today = DateTime.now().toUtc();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.room == null ? 'Arena · today' : 'Arena · ${s.room!.name}'),
        actions: [
          IconButton(tooltip: 'Your arena', icon: const Icon(Icons.account_circle_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ArenaProfileScreen()))),
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded), onPressed: ctl.refresh),
        ],
      ),
      body: s.loading && s.board.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : s.error != null && s.profile == null
              ? _Unavailable(message: s.error!, onRetry: ctl.load)
              : RefreshIndicator(
                  onRefresh: ctl.refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _RoomChips(state: s, ctl: ctl),
                      const SizedBox(height: 12),
                      if (!s.status.hasEntry)
                        _SubmitCard(state: s, onSubmit: () => _pickAndSubmit(context, ctl, s))
                      else if (s.myEntry != null)
                        _MyEntryCard(entry: s.myEntry!, onDelete: ctl.deleteMyEntry)
                      else
                        _EnteredLockedCard(state: s, onDelete: ctl.deleteMyEntry),
                      const SizedBox(height: 12),
                      if (s.needsToRate)
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ArenaRoundsScreen())),
                          icon: const Icon(Icons.compare_arrows_rounded),
                          label: Text('Rate your set  ·  ${s.status.left} duel${s.status.left == 1 ? '' : 's'}'),
                        )
                      else if (s.status.hasEntry && !s.status.unlocked)
                        const _Hint('Nobody else has entered yet — the board opens once there is a set to rate.'),
                      const SizedBox(height: 20),
                      if (!s.status.unlocked)
                        _LockedBoard(status: s.status)
                      else ...[
                      Row(
                        children: [
                          Text('Leaderboard', style: Theme.of(context).textTheme.titleLarge),
                          const Spacer(),
                          SegmentedButton<String>(
                            style: const ButtonStyle(visualDensity: VisualDensity.compact),
                            segments: const [ButtonSegment(value: 'global', label: Text('All')), ButtonSegment(value: 'friends', label: Text('Friends'))],
                            selected: {s.scope},
                            onSelectionChanged: (v) => ctl.setScope(v.first),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${s.board.length} photos · ${today.day}/${today.month} UTC', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 8),
                      if (s.board.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            s.scope == 'friends' ? 'No friends have entered today. Long-press a photo on the board to follow someone.' : 'No photos yet today. Be the first.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        )
                      else
                        for (final row in s.board) _BoardTile(row: row, ctl: ctl).animate(delay: (row.rank.clamp(0, 12) * 30).ms).fadeIn(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Future<void> _pickAndSubmit(BuildContext context, ArenaController ctl, ArenaState s) async {
    if (!s.consent) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Before your first entry'),
          content: const Text(
            'The one photo you pick will be uploaded (downsized, location and camera data removed) and shown to other players so they can rank it. '
            'Nothing else leaves your phone. You can delete an entry any time.\n\nYou must be 13 or older. No nudity, hate, or other people\'s private photos.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('I understand')),
          ],
        ),
      );
      if (ok != true) return;
      await ctl.acceptConsent();
    }
    if (!context.mounted) return;
    final id = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (_) => const _PickerSheet(),
    );
    if (id == null) return;
    HapticFeedback.mediumImpact();
    final ok = await ctl.submit(id);
    if (!ok || !context.mounted) return;
    // Straight into rating the set: that is what unlocks today's board.
    if (ref.read(arenaProvider).needsToRate) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ArenaRoundsScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your photo is in. The board opens once there is a set to rate.')));
    }
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.public_off_rounded, size: 56, color: Colors.white38),
          const SizedBox(height: 16),
          const Text('Arena is online-only', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      ),
    );
  }
}

class _RoomChips extends StatelessWidget {
  const _RoomChips({required this.state, required this.ctl});
  final ArenaState state;
  final ArenaController ctl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('Global'), avatar: const Icon(Icons.public_rounded, size: 16), selected: state.roomId == null, onSelected: (_) => ctl.selectRoom(null))),
          for (final r in state.rooms)
            Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(r.name), selected: state.roomId == r.id, onSelected: (_) => ctl.selectRoom(r.id))),
          ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('Room'), onPressed: () => _roomDialog(context, ctl)),
        ],
      ),
    );
  }

  Future<void> _roomDialog(BuildContext context, ArenaController ctl) async {
    final name = TextEditingController();
    final code = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Private arena'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Create a room (name)')),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: () async { if (name.text.trim().isNotEmpty) { Navigator.pop(ctx); await ctl.createRoom(name.text.trim()); } }, child: const Text('Create')),
          const Divider(height: 28),
          TextField(controller: code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Join with a code')),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: () async { if (code.text.trim().isNotEmpty) { Navigator.pop(ctx); await ctl.joinRoom(code.text.trim()); } }, child: const Text('Join')),
        ]),
      ),
    );
  }
}

class _SubmitCard extends StatelessWidget {
  const _SubmitCard({required this.state, required this.onSubmit});
  final ArenaState state;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Today\'s question', style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        const Text('Your best photo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('One photo per day, taken today. After you enter you rate a set of other people\'s photos — and only then does today\'s board open. Yesterday\'s boards are final and public.', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: state.busy ? null : onSubmit, icon: const Icon(Icons.upload_rounded), label: Text(state.busy ? 'Uploading…' : 'Enter a photo')),
      ]),
    );
  }
}

class _MyEntryCard extends StatelessWidget {
  const _MyEntryCard({required this.entry, required this.onDelete});
  final MyEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        SizedBox(width: 96, height: 120, child: ArenaImage(e.storagePath, borderRadius: 12)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('YOUR PHOTO TODAY', style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text(e.settled ? '#${e.rank} of ${e.total}' : 'Settling · ${e.duels}/6 duels', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(e.settled ? 'Top ${e.percentile}% · ${e.wins}–${e.duels - e.wins}' : 'Others are rating it now', style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 6),
            TextButton.icon(onPressed: () => _confirmDelete(context), icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Withdraw')),
          ]),
        ),
      ]),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw today\'s photo?'),
        content: const Text('It is removed from the board and deleted from the server. You cannot enter another photo today.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Withdraw'))],
      ),
    );
    if (ok == true) onDelete();
  }
}

class _EnteredLockedCard extends StatelessWidget {
  const _EnteredLockedCard({required this.state, required this.onDelete});
  final ArenaState state;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('YOUR PHOTO TODAY', style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        const Text('You\'re in.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text(state.status.left > 0 ? 'Rate your set of ${state.status.required} to see where it stands.' : 'Waiting for other entries.', style: const TextStyle(color: Colors.white60)),
        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Withdraw'))),
      ]),
    );
  }
}

class _LockedBoard extends StatelessWidget {
  const _LockedBoard({required this.status});
  final ArenaStatus status;

  @override
  Widget build(BuildContext context) {
    Widget step(bool done, String text) => Row(children: [
          Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: done ? AppTheme.accent : Colors.white38, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: done ? Colors.white : Colors.white70)),
        ]);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.lock_outline_rounded, color: Colors.white54), const SizedBox(width: 8), Text('Today\'s board', style: Theme.of(context).textTheme.titleLarge)]),
        const SizedBox(height: 6),
        const Text('Nobody sees today\'s standings before contributing.', style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 12),
        step(status.hasEntry, 'Enter a photo taken today'),
        const SizedBox(height: 6),
        step(status.unlocked, status.required == 0 ? 'Rate a set (once others enter)' : 'Rate your set  ·  ${status.duelsToday}/${status.required}'),
      ]),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 13)));
}

class _BoardTile extends StatelessWidget {
  const _BoardTile({required this.row, required this.ctl});
  final BoardRow row;
  final ArenaController ctl;

  @override
  Widget build(BuildContext context) {
    final r = row;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: r.mine ? AppTheme.accent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: r.mine ? Border.all(color: AppTheme.accent, width: 1.5) : null,
      ),
      child: Row(children: [
        SizedBox(width: 36, child: Text(r.settled ? '#${r.rank}' : '·', style: TextStyle(fontWeight: FontWeight.w800, color: r.rank <= 3 && r.settled ? AppTheme.accent : Colors.white70))),
        SizedBox(width: 64, height: 80, child: ArenaImage(r.storagePath, borderRadius: 10, onLongPress: r.mine ? null : () => _menu(context))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.mine ? 'You' : r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(r.settled ? '${r.score.round()} · ${r.wins}–${r.duels - r.wins}' : 'settling · ${r.duels}/6', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Future<void> _menu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.person_add_alt_1_rounded), title: Text('Follow ${row.name}'), onTap: () => Navigator.pop(ctx, 'follow')),
          ListTile(leading: const Icon(Icons.flag_outlined), title: const Text('Report this photo'), onTap: () => Navigator.pop(ctx, 'report')),
          ListTile(leading: const Icon(Icons.block), title: Text('Block ${row.name}'), onTap: () => Navigator.pop(ctx, 'block')),
        ]),
      ),
    );
    if (action == 'follow') {
      await ctl.follow(row.userId);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Following ${row.name}. Use the Friends filter to see them.')));
    } else if (action == 'report') {
      await ctl.report(row.entryId);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported. Thanks — we review these.')));
    } else if (action == 'block') {
      await ctl.block(row.userId);
    }
  }
}

/// Pick today's entry: only photos taken today, best-ranked first.
class _PickerSheet extends ConsumerWidget {
  const _PickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(rankingProvider).value ?? const [];
    final today = all.where((p) => p.takenAt != null && isFromToday(p.takenAt!)).toList();
    final suggestions = onePerMoment(today.where((p) => p.observations > 0).toList(), keys: momentKeys(all));
    final suggested = {for (final p in suggestions) p.id};
    final rest = today.where((p) => !suggested.contains(p.id)).toList();
    if (today.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.photo_camera_outlined, size: 48, color: Colors.white38),
          SizedBox(height: 12),
          Text('No photos from today yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('The arena only takes photos taken today. Go shoot one — the app picks it up automatically.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
          SizedBox(height: 16),
        ]),
      );
    }
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, scroll) => CustomScrollView(
        controller: scroll,
        slivers: [
          const SliverPadding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), sliver: SliverToBoxAdapter(child: Text('Pick today\'s photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)))),
          if (suggestions.isNotEmpty) ...[
            const SliverPadding(padding: EdgeInsets.fromLTRB(16, 4, 16, 8), sliver: SliverToBoxAdapter(child: Text('Your best of today', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)))),
            _grid(context, suggestions),
          ],
          if (rest.isNotEmpty) ...[
            const SliverPadding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), sliver: SliverToBoxAdapter(child: Text('Taken today', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)))),
            _grid(context, rest),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, List photos) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 0.8),
          delegate: SliverChildBuilderDelegate(
            (_, i) => PhotoTile(mediaId: photos[i].mediaId, size: ThumbCacheSizes.grid, borderRadius: 10, peekable: false, onTap: () => Navigator.pop(context, photos[i].id as int)),
            childCount: photos.length,
          ),
        ),
      );
}
