import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';

/// Three steps: promise → permission → scope. Then straight into a hand.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _busy = false;
  String? _error;

  Future<void> _permission() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(photoSourceProvider).requestAccess();
    if (!mounted) return;
    if (ok) {
      setState(() {
        _step = 2;
        _busy = false;
      });
    } else {
      setState(() {
        _busy = false;
        _error = 'Photo access is needed to play. You can grant it in system settings.';
      });
    }
  }

  Future<void> _pickFolder() async {
    final dir = await getDirectoryPath();
    if (dir == null || !mounted) return;
    await _start(months: null, folders: [dir]);
  }

  Future<void> _start({required int? months, List<String>? folders}) async {
    setState(() => _busy = true);
    await ref.read(scopeProvider.notifier).set(months: months, folders: folders);
    final scope = ref.read(scopeProvider)!;
    await ref.read(photoRepoProvider).setPref(prefOnboarded, '1');
    // Kick off the scan; play begins once the first page is in.
    final scanFuture = ref.read(scanProvider.notifier).start(scope);
    for (var i = 0; i < 50; i++) {
      final p = ref.read(scanProvider);
      if (p != null && (p.indexed > 0 || p.done)) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    scanFuture.ignore();
    if (mounted) context.go('/play');
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scanProvider);
    final desktop = ref.watch(photoSourceProvider).usesFolders;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (_step) {
              0 => _Page(
                  key: const ValueKey(0),
                  icon: Icons.style_rounded,
                  title: 'PhotoRank',
                  body: 'A tiny game that sorts your camera roll.\n\n'
                      'Every swipe makes your favourites clearer. Nothing is ever deleted, hidden, or uploaded — '
                      'your photos never leave this phone.',
                  action: 'Let\'s go',
                  onAction: () => setState(() => _step = 1),
                ),
              1 when desktop => _Page(
                  key: const ValueKey(1),
                  icon: Icons.folder_open_rounded,
                  title: 'Your photos',
                  body: 'Pick a folder — every photo inside it (and its subfolders) joins the game. You can add more folders later in Settings. Nothing is moved, changed or uploaded.',
                  action: _busy ? (scan == null ? 'Indexing…' : 'Indexing ${scan.indexed}/${scan.total}…') : 'Choose a folder',
                  onAction: _busy ? null : _pickFolder,
                ),
              1 => _Page(
                  key: const ValueKey(1),
                  icon: Icons.photo_library_rounded,
                  title: 'Your photos',
                  body: 'PhotoRank reads photos already on this phone and stores only your ratings.',
                  action: _busy ? 'Asking…' : 'Allow photo access',
                  onAction: _busy ? null : _permission,
                  error: _error,
                  secondary: _error == null ? null : ('Open settings', PhotoManager.openSetting),
                ),
              _ => _Page(
                  key: const ValueKey(2),
                  icon: Icons.tune_rounded,
                  title: 'Where to start?',
                  body: 'Your whole library is in play by default — every photo gets its chance. You can narrow the scope any time in Settings.',
                  action: _busy
                      ? (scan == null ? 'Indexing…' : 'Indexing ${scan.indexed}…')
                      : 'All my photos',
                  onAction: _busy ? null : () => _start(months: null),
                  secondary: _busy ? null : ('Just the last 12 months', () => _start(months: 12)),
                ),
            },
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    this.secondary,
    this.error,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback? onAction;
  final (String, VoidCallback)? secondary;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Icon(icon, size: 64, color: AppTheme.accent).animate().scale(curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(body, style: const TextStyle(fontSize: 16, height: 1.45, color: Colors.white70)),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: Colors.orangeAccent)),
        ],
        const Spacer(),
        FilledButton(onPressed: onAction, child: Text(action)),
        if (secondary != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: secondary!.$2, child: Text(secondary!.$1)),
        ],
      ],
    );
  }
}
