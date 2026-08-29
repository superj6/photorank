import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme.dart';
import '../../data/arena/arena_models.dart';
import 'arena_providers.dart';
import 'publish_set_sheet.dart';
import 'set_boards_screen.dart';
import 'set_rank_screen.dart';
import 'sets_providers.dart';

/// The app's FilledButton theme is full-width (min width ∞); inside a Row
/// a button needs a finite minimum or layout throws.
final inlineButton = FilledButton.styleFrom(minimumSize: const Size(0, 44));

/// Friends: your published Top N and how friends rank it, friends' sets to
/// rank, and who you follow. Friends are mutual follows.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key, this.publishOnOpen = false});

  /// Open the publish sheet straight away (from the Ranking menu).
  final bool publishOnOpen;

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(setsProvider.notifier).refresh();
      if (widget.publishOnOpen && mounted) _publish();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(setsProvider);
    final ctl = ref.read(setsProvider.notifier);
    ref.listen(setsProvider.select((s) => s.error), (_, err) {
      if (err != null && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    });
    final friends = ref.watch(friendsProvider);
    final profile = ref.watch(arenaProvider).profile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(tooltip: 'Join a set by code', icon: const Icon(Icons.qr_code_rounded), onPressed: () => _join(context)),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(friendsProvider);
              ctl.refresh();
            },
          ),
        ],
      ),
      body: s.loading && s.sets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(friendsProvider);
                await ctl.refresh();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _MySetCard(set: s.mine, busy: s.busy, username: profile?.username, onPublish: _publish, onUnpublish: _unpublish, onVisibility: ctl.setVisibility),
                  const SizedBox(height: 20),
                  Text('Friends\' sets', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  const Text('Rank a friend\'s Top N once; then compare your order with theirs.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  if (s.friends.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Text('No sets to rank yet. When a friend publishes their Top N it shows up here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)))
                  else
                    for (final (i, f) in s.friends.indexed) _FriendSetTile(set: f).animate(delay: (i * 40).ms).fadeIn(),
                  const SizedBox(height: 20),
                  Row(children: [
                    Text('People', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton.icon(onPressed: () => _find(context), icon: const Icon(Icons.person_search_rounded, size: 18), label: const Text('Find by username')),
                  ]),
                  const Text('Friends are people who follow each other.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  friends.when(
                    loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => Text('$e'),
                    data: (list) => Column(children: [
                      if (list.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Nobody yet. Find a friend by their arena username, or long-press a photo on the arena board.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60))),
                      for (final f in list) _PersonTile(row: f, onToggle: () => ctl.follow(f.id, unfollow: f.iFollow)),
                    ]),
                  ),
                ],
              ),
            ),
    );
  }

  Future<bool> _ensureUsername() async {
    final arena = ref.read(arenaProvider);
    if (arena.profile == null) await ref.read(arenaProvider.notifier).load();
    if (ref.read(arenaProvider).profile?.username != null) return true;
    if (!mounted) return false;
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a username first'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'letters, numbers, underscore'), onSubmitted: (v) => Navigator.pop(ctx, v)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Save'))],
      ),
    );
    final u = v?.trim().toLowerCase();
    if (u == null || !RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(u)) return false;
    await ref.read(arenaProvider.notifier).claimUsername(u);
    return ref.read(arenaProvider).profile?.username != null;
  }

  Future<void> _publish() async {
    if (!await _ensureUsername() || !mounted) return;
    final mine = ref.read(setsProvider).mine;
    final choice = await PublishSetSheet.show(context, title: mine?.title, visibility: mine?.visibility ?? 'friends');
    if (choice == null) return;
    HapticFeedback.mediumImpact();
    final ok = await ref.read(setsProvider.notifier).publish(photoIds: choice.photoIds, title: choice.title, visibility: choice.visibility);
    if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Published your Top ${choice.photoIds.length}.')));
  }

  Future<void> _unpublish() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpublish your set?'),
        content: const Text('The photos are removed from the server, along with every friend\'s ranking of them.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unpublish'))],
      ),
    );
    if (ok == true) await ref.read(setsProvider.notifier).unpublish();
  }

  Future<void> _join(BuildContext context) async {
    final c = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join a set by code'),
        content: TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(hintText: '8-character code'), onSubmitted: (v) => Navigator.pop(ctx, v)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Join'))],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    final s = await ref.read(setsProvider.notifier).join(code);
    if (s != null && context.mounted) Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SetRankScreen(setId: s.id)));
  }

  Future<void> _find(BuildContext context) async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Find by username'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(prefixText: '@'), onSubmitted: (v) => Navigator.pop(ctx, v)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Search'))],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    final api = await ref.read(arenaApiProvider.future);
    final found = await api?.findProfile(name);
    if (!context.mounted) return;
    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No player called @${name.trim().toLowerCase()}.')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
            title: Text(found.name),
            subtitle: Text(found.friends ? 'Friends' : found.followsMe ? 'Follows you — follow back to become friends' : found.iFollow ? 'You follow them' : 'Not following'),
          ),
          ListTile(
            leading: Icon(found.iFollow ? Icons.person_remove_rounded : Icons.person_add_alt_1_rounded),
            title: Text(found.iFollow ? 'Unfollow' : 'Follow'),
            onTap: () async {
              Navigator.pop(ctx);
              await ref.read(setsProvider.notifier).follow(found.id, unfollow: found.iFollow);
            },
          ),
        ]),
      ),
    );
  }
}

class _MySetCard extends ConsumerWidget {
  const _MySetCard({required this.set, required this.busy, required this.username, required this.onPublish, required this.onUnpublish, required this.onVisibility});
  final SetSummary? set;
  final bool busy;
  final String? username;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final ValueChanged<String> onVisibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = set;
    final raters = s == null ? null : ref.watch(setRatersProvider(s.id)).value;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.accent.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.04)]), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium_rounded, color: AppTheme.accent),
          const SizedBox(width: 8),
          Expanded(child: Text(s == null ? 'Your Top N' : s.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          if (s != null)
            PopupMenuButton<String>(
              onSelected: (v) => v == 'unpublish' ? onUnpublish() : v == 'replace' ? onPublish() : onVisibility(v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'replace', child: Text('Replace photos')),
                const PopupMenuDivider(),
                CheckedPopupMenuItem(value: 'friends', checked: s.visibility == 'friends', child: const Text('Friends only')),
                CheckedPopupMenuItem(value: 'link', checked: s.visibility == 'link', child: const Text('Friends + link')),
                CheckedPopupMenuItem(value: 'public', checked: s.visibility == 'public', child: const Text('Public')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'unpublish', child: Text('Unpublish')),
              ],
            ),
        ]),
        const SizedBox(height: 6),
        if (s == null) ...[
          const Text('Publish your Top 10 (or any 3–50) so friends can see it and rank it their way. Friends only by default.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: busy ? null : onPublish, icon: const Icon(Icons.cloud_upload_rounded), label: Text(busy ? 'Publishing…' : 'Publish my Top 10')),
        ] else ...[
          Text('${s.items} photos · ${_vis(s.visibility)} · ${s.raters} friend${s.raters == 1 ? '' : 's'} ranked it', style: const TextStyle(color: Colors.white70)),
          if (raters != null && raters.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final r in raters)
                ActionChip(
                  avatar: Icon(r.done ? Icons.check_circle_rounded : Icons.hourglass_top_rounded, size: 16, color: r.done ? AppTheme.accent : Colors.white54),
                  label: Text(r.done ? r.name : '${r.name} · ${r.duels}/${s.requiredDuels}'),
                  onPressed: r.done ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SetBoardsScreen(set: s, initialRater: r.id))) : null,
                ),
            ]),
          ],
          const SizedBox(height: 12),
          Row(children: [
            FilledButton.icon(
              style: inlineButton,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SetBoardsScreen(set: s))),
              icon: const Icon(Icons.leaderboard_rounded),
              label: const Text('Boards'),
            ),
            const SizedBox(width: 8),
            if (s.visibility != 'friends' && s.linkCode != null)
              OutlinedButton.icon(
                onPressed: () => SharePlus.instance.share(ShareParams(text: 'Rank my top photos on PhotoRank — join with code ${s.linkCode}')),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(s.linkCode!),
              ),
          ]),
        ],
      ]),
    );
  }

  static String _vis(String v) => switch (v) { 'friends' => 'friends only', 'link' => 'friends + link', _ => 'public' };
}

class _FriendSetTile extends StatelessWidget {
  const _FriendSetTile({required this.set});
  final SetSummary set;

  @override
  Widget build(BuildContext context) {
    final s = set;
    final started = s.myDuels > 0 && !s.myDone;
    return _RowTile(
      icon: s.myDone ? Icons.check_rounded : Icons.collections_rounded,
      highlight: s.myDone,
      title: '${s.ownerName} · ${s.title}',
      subtitle: '${s.items} photos · ${s.myDone ? 'you ranked it' : started ? '${s.myDuels}/${s.requiredDuels} duels' : 'not ranked yet'} · ${s.raters} ranked',
      trailing: s.myDone
          ? TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SetBoardsScreen(set: s, initialRater: 'me'))), child: const Text('Boards'))
          : FilledButton.tonal(style: inlineButton, onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SetRankScreen(setId: s.id))), child: Text(started ? 'Continue' : 'Rank it')),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.row, required this.onToggle});
  final FriendRow row;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => _RowTile(
        icon: row.friends ? Icons.people_rounded : Icons.person_outline_rounded,
        highlight: row.friends,
        title: row.name,
        subtitle: row.friends ? 'Friends${row.hasSet ? ' · has a set' : ''}' : row.followsMe ? 'Follows you — follow back to become friends' : 'You follow them · waiting for a follow back',
        trailing: TextButton(onPressed: onToggle, child: Text(row.iFollow ? 'Unfollow' : 'Follow back')),
      );
}

/// Avatar + two lines + an action. (ListTile asserts when its trailing
/// button is measured inside this list, so lay it out by hand.)
class _RowTile extends StatelessWidget {
  const _RowTile({required this.icon, required this.highlight, required this.title, required this.subtitle, required this.trailing});
  final IconData icon;
  final bool highlight;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          CircleAvatar(backgroundColor: highlight ? AppTheme.accent.withValues(alpha: 0.25) : Colors.white10, child: Icon(icon, color: highlight ? AppTheme.accent : Colors.white70)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          trailing,
        ]),
      );
}
