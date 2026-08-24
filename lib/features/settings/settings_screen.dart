import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/rating/observation.dart';
import '../play/session_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _modeNames = {
    GameMode.duel: ('Duel', 'Two photos — tap the one you like more'),
    GameMode.vibeCheck: ('Vibe check', 'Swipe: feeling it / not feeling it'),
    GameMode.rate: ('Rate', 'One photo, five stars'),
    GameMode.bestOfBurst: ('Best of burst', 'Pick the keeper from near-identical shots'),
    GameMode.sort3: ('Sort three', 'Tap three photos in order'),
    GameMode.challenger: ('Challenger', 'A newcomer vs one of your Top 50'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(dealerSettingsProvider);
    final settings = ref.read(dealerSettingsProvider.notifier);
    final count = ref.watch(libraryCountProvider).value;
    final scan = ref.watch(scanProvider);
    final scope = ref.watch(scopeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Section('Game mix'),
          for (final e in _modeNames.entries)
            SwitchListTile(
              title: Text(e.value.$1),
              subtitle: Text(e.value.$2),
              value: (config.modeWeights[e.key] ?? 0) > 0,
              onChanged: (v) => settings.setMode(e.key, v),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(label: const Text('Shuffle all'), onPressed: settings.shuffleAll),
                for (final e in _modeNames.entries)
                  ActionChip(label: Text('Only ${e.value.$1}'), onPressed: () => settings.solo(e.key)),
              ],
            ),
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
            title: Text('${count ?? '…'} photos in play'),
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
                ActionChip(
                  label: const Text('Last 12 months'),
                  onPressed: () => _setScope(ref, months: 12),
                ),
                ActionChip(
                  label: const Text('Last 3 years'),
                  onPressed: () => _setScope(ref, months: 36),
                ),
                ActionChip(
                  label: const Text('Everything'),
                  onPressed: () => _setScope(ref, months: null),
                ),
                ActionChip(
                  avatar: const Icon(Icons.refresh, size: 16),
                  label: const Text('Rescan'),
                  onPressed: scope == null ? null : () => ref.read(scanProvider.notifier).start(scope, markMissing: true),
                ),
              ],
            ),
          ),
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

  String _scopeLabel(DateTime? since) => since == null ? 'Everything' : 'Since ${since.year}-${since.month.toString().padLeft(2, '0')}';

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
