import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/notifications.dart';
import '../../app/providers.dart';
import '../../core/beats/beat.dart';
import '../../core/beats/unlocks.dart';
import '../../core/stats/progress.dart';
import '../../core/rating/observation.dart';
import '../arena/arena_providers.dart';
import '../play/session_controller.dart';
import '../widgets/axis_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const modeNames = {
    GameMode.duel: ('Duel', 'Two photos — tap the one you like more'),
    GameMode.vibeCheck: ('Vibe check', 'Swipe: feeling it / not feeling it'),
    GameMode.rate: ('Rate', 'One photo, five stars'),
    GameMode.bestOfBurst: ('Best of burst', 'Pick the keeper from near-identical shots'),
    GameMode.sort3: ('Sort three', 'Tap three photos in order'),
    GameMode.challenger: ('Challenger', 'A newcomer vs one of your Top 50'),
    GameMode.rerankTop: ('Re-rank Top 10', 'Sort three of your very best'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dealerSettingsProvider);
    final settings = ref.read(dealerSettingsProvider.notifier);
    final count = ref.watch(libraryCountProvider).value;
    final decisions = ref.watch(decisionsProvider).value ?? 0;
    final unlockAll = ref.watch(unlockAllProvider);
    final unlocked = Unlocks.unlocked(decisions, all: unlockAll);
    final scan = ref.watch(scanProvider);
    final scope = ref.watch(scopeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Section('Progress'),
          _ProgressTile(decisions: decisions),
          const _Section('Game mix'),
          for (final e in modeNames.entries)
            if (unlocked.contains(e.key))
              SwitchListTile(
                title: Text(e.value.$1),
                subtitle: Text(e.value.$2),
                value: (config.modeWeights[e.key] ?? 0) > 0,
                onChanged: (v) => settings.setMode(e.key, v),
              )
            else
              ListTile(
                enabled: false,
                leading: const Icon(Icons.lock_outline),
                title: Text(e.value.$1),
                subtitle: Text('Unlocks at ${Unlocks.thresholds[e.key]} decisions — you\'re at $decisions'),
              ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(label: const Text('Shuffle all'), onPressed: settings.shuffleAll),
                for (final e in modeNames.entries)
                  if (unlocked.contains(e.key))
                    ActionChip(label: Text('Only ${e.value.$1}'), onPressed: () => settings.solo(e.key)),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Unlock everything'),
            subtitle: const Text('Skip the progressive unlocks and play every mode now'),
            value: unlockAll,
            onChanged: (v) async {
              await ref.read(unlockAllProvider.notifier).set(v);
              ref.invalidate(sessionProvider);
            },
          ),
          const _Section('Axes'),
          const _AxesList(),
          const _Section('Hand size'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 10, label: Text('10')),
                ButtonSegment(value: 20, label: Text('20')),
                ButtonSegment(value: 50, label: Text('50')),
              ],
              selected: {config.handSize},
              onSelectionChanged: (s) => settings.setHandSize(s.first),
            ),
          ),
          const _Section('Library'),
          ListTile(
            title: Text('${count ?? '…'} photos in play · $decisions decisions'),
            subtitle: Text(scan == null
                ? (scope == null ? 'No scope set' : scope.folders != null ? '${scope.folders!.length} folder(s)' : _scopeLabel(scope.since))
                : scan.done
                    ? 'Scan complete (${scan.indexed})'
                    : 'Scanning ${scan.indexed}/${scan.total}…'),
          ),
          if (ref.watch(photoSourceProvider).usesFolders) ...[
            for (final f in scope?.folders ?? const <String>[])
              ListTile(
                dense: true,
                leading: const Icon(Icons.folder_outlined),
                title: Text(f, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () async {
                    final rest = [...?scope?.folders]..remove(f);
                    await ref.read(scopeProvider.notifier).setFolders(rest);
                    final sc = ref.read(scopeProvider);
                    if (sc != null) await ref.read(scanProvider.notifier).start(sc, markMissing: true);
                    ref.invalidate(sessionProvider);
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(spacing: 8, children: [
                ActionChip(
                  avatar: const Icon(Icons.create_new_folder_outlined, size: 16),
                  label: const Text('Add a folder'),
                  onPressed: () async {
                    final dir = await getDirectoryPath();
                    if (dir == null) return;
                    await ref.read(scopeProvider.notifier).setFolders([...?scope?.folders, dir]);
                    final sc = ref.read(scopeProvider);
                    if (sc != null) await ref.read(scanProvider.notifier).start(sc);
                    ref.invalidate(sessionProvider);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.refresh, size: 16),
                  label: const Text('Rescan'),
                  onPressed: scope == null ? null : () => ref.read(scanProvider.notifier).start(scope, markMissing: true),
                ),
              ]),
            ),
          ] else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(label: const Text('Last 12 months'), onPressed: () => _setScope(ref, months: 12)),
                ActionChip(label: const Text('Last 3 years'), onPressed: () => _setScope(ref, months: 36)),
                ActionChip(label: const Text('Everything'), onPressed: () => _setScope(ref, months: null)),
                ActionChip(
                  avatar: const Icon(Icons.refresh, size: 16),
                  label: const Text('Rescan'),
                  onPressed: scope == null ? null : () => ref.read(scanProvider.notifier).start(scope, markMissing: true),
                ),
              ],
            ),
          ),
          const _Section('Moments'),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Your moments'),
            subtitle: const Text('Every reveal, milestone and unlock so far'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/moments'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded),
            title: Text('Show my year · ${DateTime.now().year}'),
            subtitle: const Text('Your year in photos, any time'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final ok = await ref.read(sessionProvider.notifier).showYear(DateTime.now().year);
              if (!context.mounted) return;
              if (ok) {
                context.go('/play');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Play a few more hands first — not enough to recap yet.')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_rounded),
            title: const Text('Pass the phone'),
            subtitle: const Text('A friend plays on your photos — do you agree? Do they know you?'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/guest'),
          ),
          const _Section('Arena'),
          _ArenaProfileTile(),
          const _Section('Reminders'),
          _NotifyToggle(
            prefKey: 'notify_weekly',
            title: 'Weekly recap',
            subtitle: 'A nudge when your week in photos is ready',
            apply: Notifications.setWeeklyRecap,
          ),
          const _ArenaReminderTile(),
          _NotifyToggle(
            prefKey: 'notify_daily',
            title: 'Daily hand',
            subtitle: 'One reminder a day that photos await a verdict',
            apply: Notifications.setDailyReminder,
          ),
          if (kDebugMode) ...[
            const _Section('Debug · fire a beat'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final k in BeatKind.values)
                    ActionChip(
                      label: Text(k.name),
                      onPressed: () async {
                        await ref.read(sessionProvider.notifier).debugFire(k);
                        if (context.mounted) context.go('/play');
                      },
                    ),
                ],
              ),
            ),
          ],
          const _Section('About'),
          const ListTile(
            title: Text('Your photos never leave this phone.'),
            subtitle: Text('PhotoRank only stores ratings. Nothing is ever deleted, hidden, or uploaded.'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _scopeLabel(DateTime? since) =>
      since == null ? 'Everything' : 'Since ${since.year}-${since.month.toString().padLeft(2, '0')}';

  Future<void> _setScope(WidgetRef ref, {required int? months}) async {
    await ref.read(scopeProvider.notifier).set(months: months);
    final scope = ref.read(scopeProvider);
    if (scope != null) {
      await ref.read(scanProvider.notifier).start(scope, markMissing: true);
      ref.invalidate(sessionProvider);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(fontSize: 12, letterSpacing: 1.2, color: Colors.white54, fontWeight: FontWeight.w700)),
    );
  }
}

class _AxesList extends ConsumerWidget {
  const _AxesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final axes = ref.watch(axesProvider).value ?? const [];
    final current = ref.watch(axisIdProvider).value;
    return Column(
      children: [
        for (final a in axes)
          ListTile(
            leading: Icon(a.id == current ? Icons.radio_button_checked : Icons.radio_button_off, color: a.id == current ? const Color(0xFFFF6B4A) : Colors.white38),
            title: Text(a.name),
            subtitle: Text(a.isDefault ? 'Default axis' : 'Custom axis'),
            trailing: a.isDefault
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Delete "${a.name}"?'),
                          content: const Text('Its ratings are removed. Photos are never touched.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) await ref.read(axisSwitcherProvider.notifier).delete(a.id);
                    },
                  ),
            onTap: () => ref.read(axisSwitcherProvider.notifier).select(a.id),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(avatar: const Icon(Icons.add, size: 16), label: const Text('Add an axis'), onPressed: () => addAxisDialog(context, ref)),
          ),
        ),
      ],
    );
  }
}

final _factsProvider = FutureProvider.autoDispose<ProgressFacts>((ref) async {
  ref.watch(decisionsProvider);
  final ctl = ref.read(sessionProvider.notifier);
  return ctl.progressFacts();
});

class _ProgressTile extends ConsumerWidget {
  const _ProgressTile({required this.decisions});
  final int decisions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = Level.fromXp(decisions);
    final facts = ref.watch(_factsProvider).value;
    final earned = facts == null ? <String>{} : Badges.earned(facts);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Level ${level.level} · ${Level.title(level.level)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: level.fraction, minHeight: 6, backgroundColor: Colors.white10),
          ),
          const SizedBox(height: 4),
          Text('$decisions decisions · ${facts?.streak ?? 0}-day streak · ${earned.length}/${Badges.all.length} badges',
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in Badges.all)
                Tooltip(
                  message: b.description,
                  child: Chip(
                    avatar: Icon(earned.contains(b.id) ? Icons.workspace_premium_rounded : Icons.lock_outline,
                        size: 16, color: earned.contains(b.id) ? const Color(0xFFFF6B4A) : Colors.white30),
                    label: Text(b.title, style: TextStyle(color: earned.contains(b.id) ? Colors.white : Colors.white38)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArenaProfileTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(arenaProvider);
    final name = s.profile?.username;
    return ListTile(
      leading: const Icon(Icons.badge_outlined),
      title: Text(name == null ? 'Claim a username' : '@$name'),
      subtitle: Text(name == null ? 'So friends can find you on the arena board' : 'Your arena name'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        if (s.profile == null) await ref.read(arenaProvider.notifier).load();
        if (!context.mounted) return;
        final c = TextEditingController(text: name ?? '');
        final v = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Username'),
            content: TextField(controller: c, decoration: const InputDecoration(hintText: 'letters, numbers, underscore'), onSubmitted: (v) => Navigator.pop(ctx, v)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Save'))],
          ),
        );
        final u = v?.trim().toLowerCase();
        if (u != null && RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(u)) await ref.read(arenaProvider.notifier).claimUsername(u);
      },
    );
  }
}

class _ArenaReminderTile extends ConsumerWidget {
  const _ArenaReminderTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(prefProvider(prefArenaReminder)).value == '1';
    final hour = int.tryParse(ref.watch(prefProvider(prefArenaReminderHour)).value ?? '') ?? 18;
    Future<void> apply(bool v, int h) async {
      if (v && !await Notifications.requestPermission()) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications are off for PhotoRank in system settings.')));
        return;
      }
      final entered = ref.read(arenaProvider).status.hasEntry;
      await Notifications.setArenaReminder(v, hour: h, skipToday: entered);
      final prefs = ref.read(photoRepoProvider);
      await prefs.setPref(prefArenaReminder, v ? '1' : '0');
      await prefs.setPref(prefArenaReminderHour, '$h');
      ref.invalidate(prefProvider(prefArenaReminder));
      ref.invalidate(prefProvider(prefArenaReminderHour));
    }
    return SwitchListTile(
      title: const Text('Arena: enter today\'s photo'),
      subtitle: Row(children: [
        Text(on ? 'Daily at ' : 'A daily nudge; skipped on days you already entered'),
        if (on)
          InkWell(
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: hour, minute: 0));
              if (t != null) await apply(true, t.hour);
            },
            child: Text('${hour.toString().padLeft(2, '0')}:00  (change)', style: const TextStyle(color: Color(0xFFFF6B4A), fontWeight: FontWeight.w600)),
          ),
      ]),
      value: on,
      onChanged: (v) => apply(v, hour),
    );
  }
}

class _NotifyToggle extends ConsumerWidget {
  const _NotifyToggle({required this.prefKey, required this.title, required this.subtitle, required this.apply});
  final String prefKey;
  final String title;
  final String subtitle;
  final Future<void> Function(bool) apply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(prefProvider(prefKey)).value == '1';
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (v) async {
        if (v && !await Notifications.requestPermission()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications are off for PhotoRank in system settings.')));
          }
          return;
        }
        await apply(v);
        await ref.read(photoRepoProvider).setPref(prefKey, v ? '1' : '0');
        ref.invalidate(prefProvider(prefKey));
      },
    );
  }
}
