import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/recovery/recovery_phrase.dart';
import 'arena_providers.dart';

/// Claim (or rename) the username. The first claim links the account to a
/// recovery phrase and shows it once; returns true when a username is set.
Future<bool> claimUsernameFlow(BuildContext context, WidgetRef ref) async {
  final arena = ref.read(arenaProvider);
  if (arena.profile == null) await ref.read(arenaProvider.notifier).load();
  if (!context.mounted) return false;
  final current = ref.read(arenaProvider).profile?.username;
  final c = TextEditingController(text: current ?? '');
  String? error;
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(current == null ? 'Pick a username' : 'Rename'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: c, autofocus: true, decoration: InputDecoration(prefixText: '@', hintText: 'letters, numbers, underscore', errorText: error), onSubmitted: (_) => Navigator.pop(ctx, c.text)),
          if (current == null) ...[
            const SizedBox(height: 10),
            const Text('You will get a recovery phrase with it — the only way back into this account on another device or after a reinstall.', style: TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Save'))],
      ),
    ),
  );
  if (name == null || name.trim().isEmpty) return false;
  try {
    final phrase = await ref.read(arenaProvider.notifier).claimUsername(name);
    if (!context.mounted) return false;
    if (phrase != null) await showRecoveryPhrase(context, phrase, username: name.trim().toLowerCase(), first: true);
    return true;
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Bad state: ', ''))));
    return false;
  }
}

/// Shows a phrase with copy; the first time it cannot be dismissed until the
/// user confirms they saved it.
Future<void> showRecoveryPhrase(BuildContext context, String phrase, {required String username, bool first = false}) async {
  var saved = !first;
  await showDialog<void>(
    context: context,
    barrierDismissible: !first,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(first ? 'Save your recovery phrase' : 'Your new recovery phrase'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('@$username', style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          SelectableText(phrase, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.accent, height: 1.4)),
          const SizedBox(height: 12),
          const Text('Write it down or put it in your password manager. It is not shown again and cannot be recovered — it is the only way to get this account back.', style: TextStyle(fontSize: 12, color: Colors.white70)),
          if (first) CheckboxListTile(contentPadding: EdgeInsets.zero, value: saved, onChanged: (v) => setState(() => saved = v ?? false), title: const Text('I saved it', style: TextStyle(fontSize: 14)), controlAffinity: ListTileControlAffinity.leading),
        ]),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: '@$username · $phrase'));
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Copied')));
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy'),
          ),
          FilledButton(onPressed: saved ? () => Navigator.pop(ctx) : null, child: const Text('Done')),
        ],
      ),
    ),
  );
}

/// Sign this device into an existing account.
Future<bool> restoreAccountFlow(BuildContext context, WidgetRef ref) async {
  final u = TextEditingController();
  final p = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Restore an account'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: u, autofocus: true, decoration: const InputDecoration(prefixText: '@', labelText: 'Username')),
        const SizedBox(height: 8),
        TextField(controller: p, decoration: const InputDecoration(labelText: 'Recovery phrase', hintText: 'five words'), onSubmitted: (_) => Navigator.pop(ctx, true)),
        const SizedBox(height: 8),
        const Text('This device\'s current arena account is replaced by the restored one. Your local photo ranking is not affected.', style: TextStyle(fontSize: 12, color: Colors.white54)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore'))],
    ),
  );
  if (ok != true) return false;
  if (!RecoveryPhrase.looksValid(p.text)) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A recovery phrase has five words.')));
    return false;
  }
  try {
    await ref.read(arenaProvider.notifier).restore(u.text, p.text);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome back, @${u.text.trim().toLowerCase()}.')));
    return true;
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Bad state: ', ''))));
    return false;
  }
}

Future<void> newRecoveryPhraseFlow(BuildContext context, WidgetRef ref) async {
  final username = ref.read(arenaProvider).profile?.username;
  if (username == null) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('New recovery phrase?'),
      content: const Text('The old phrase stops working immediately.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate'))],
    ),
  );
  if (ok != true) return;
  try {
    final phrase = await ref.read(arenaProvider.notifier).newRecoveryPhrase();
    if (context.mounted) await showRecoveryPhrase(context, phrase, username: username, first: true);
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Bad state: ', ''))));
  }
}
