import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/notifications.dart';
import '../../app/providers.dart';
import '../../core/beats/beat.dart';
import '../../core/beats/unlocks.dart';
import '../../core/stats/progress.dart';
import '../../core/rating/observation.dart';
import '../play/session_controller.dart';

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
                ? (scope == null ? 'No scope set' : _scopeLabel(scope.since))
                : scan.done
                    ? 'Scan complete (${scan.indexed})'
                    : 'Scanning ${scan.indexed}/${scan.total}…'),
          ),
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
          const _Section('Reminders'),
          _NotifyToggle(
            prefKey: 'notify_weekly',
            title: 'Weekly recap',
            subtitle: 'A nudge when your week in photos is ready',
            apply: Notifications.setWeeklyRecap,
          ),
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
