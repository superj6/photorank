import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';

/// Bottom-nav shell. Play is the default tab so the app opens into a hand.
class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  @override
  void initState() {
    super.initState();
    // Incremental rescan on every launch so new shots join the game.
    WidgetsBinding.instance.addPostFrameCallback((_) => _rescan());
  }

  Future<void> _rescan() async {
    // Scope loads async from prefs; wait briefly for it.
    var scope = ref.read(scopeProvider);
    for (var i = 0; i < 10 && scope == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      scope = ref.read(scopeProvider);
    }
    if (scope == null || !mounted) return;
    ref.read(scanProvider.notifier).start(scope);
    _snapshot();
  }

  Future<void> _snapshot() async {
    final axis = await ref.read(axisIdProvider.future);
    final states = await ref.read(rankingRepoProvider).photoStates(axis);
    if (!mounted) return;
    await ref.read(beatRepoProvider).writeDailySnapshot(states);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (i) => widget.shell.goBranch(i, initialLocation: i == widget.shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style), label: 'Play'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Browse'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Ranking'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }
}

extension GoTo on BuildContext {
  void openPhoto(int id) => push('/photo/$id');
}
