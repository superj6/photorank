import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repo/axis_repo.dart';

/// Chip row to switch the ranking axis, with "+" to add one.
class AxisBar extends ConsumerWidget {
  const AxisBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final axes = ref.watch(axesProvider).value ?? const [];
    final current = ref.watch(axisIdProvider).value;
    if (axes.length <= 1 && current == null) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final a in axes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(a.name),
                selected: a.id == current,
                onSelected: (_) => ref.read(axisSwitcherProvider.notifier).select(a.id),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('Axis'),
            onPressed: () => addAxisDialog(context, ref),
          ),
        ],
      ),
    );
  }
}

Future<void> addAxisDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('New ranking axis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rank the same photos along a different question.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final p in AxisRepo.presets) ActionChip(label: Text(p), onPressed: () => Navigator.pop(ctx, p)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Or type your own…'),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Add')),
      ],
    ),
  );
  if (name != null && name.trim().isNotEmpty) {
    await ref.read(axisSwitcherProvider.notifier).add(name.trim());
  }
}
