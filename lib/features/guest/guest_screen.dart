import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/guest/guest.dart';
import '../beats/beat_photo.dart';
import '../play/cards/duel_card.dart';
import '../play/cards/vibe_card.dart';
import '../share/share_preview_screen.dart';
import '../widgets/photo_tile.dart';

enum GuestStage { intro, play, result }

class GuestState {
  const GuestState({this.stage = GuestStage.intro, this.mode = GuestMode.taste, this.name = '', this.cards = const [], this.index = 0, this.answers = const [], this.mediaIds = const {}, this.tooFew = false});
  final GuestStage stage;
  final GuestMode mode;
  final String name;
  final List<GuestCard> cards;
  final int index;
  final List<GuestAnswer> answers;
  final Map<int, String> mediaIds;
  final bool tooFew;
  GuestCard? get current => index < cards.length ? cards[index] : null;
  GuestResult get result => GuestResult(name: name, mode: mode, answers: answers);
  GuestState copyWith({GuestStage? stage, GuestMode? mode, String? name, List<GuestCard>? cards, int? index, List<GuestAnswer>? answers, Map<int, String>? mediaIds, bool? tooFew}) => GuestState(
      stage: stage ?? this.stage, mode: mode ?? this.mode, name: name ?? this.name, cards: cards ?? this.cards, index: index ?? this.index, answers: answers ?? this.answers, mediaIds: mediaIds ?? this.mediaIds, tooFew: tooFew ?? this.tooFew);
}

/// Pass-the-phone: a friend plays ten cards on your settled photos. Their
/// answers never touch your ranking; we only measure agreement.
class GuestController extends Notifier<GuestState> {
  @override
  GuestState build() => const GuestState();

  Future<void> start(GuestMode mode, String name) async {
    final axis = await ref.read(axisIdProvider.future);
    final states = await ref.read(rankingRepoProvider).photoStates(axis);
    final cards = GuestGame.build(states);
    if (cards.isEmpty) {
      state = state.copyWith(tooFew: true);
      return;
    }
    final ids = {for (final c in cards) ...[c.a, if (c.b != null) c.b!]};
    final rows = await ref.read(photoRepoProvider).byIds(ids);
    state = GuestState(stage: GuestStage.play, mode: mode, name: name.trim().isEmpty ? 'Your friend' : name.trim(), cards: cards, mediaIds: {for (final r in rows) r.id: r.mediaId});
  }

  void pick(int id) => _answer(GuestGame.scoreDuel(state.current!, id));
  void vibe(bool feltIt) => _answer(GuestGame.scoreVibe(state.current!, feltIt));

  void _answer(GuestAnswer a) {
    HapticFeedback.lightImpact();
    final next = state.index + 1;
    state = state.copyWith(answers: [...state.answers, a], index: next, stage: next >= state.cards.length ? GuestStage.result : GuestStage.play);
  }

  void reset() => state = const GuestState();
}

final guestProvider = NotifierProvider.autoDispose<GuestController, GuestState>(GuestController.new);

class GuestScreen extends ConsumerStatefulWidget {
  const GuestScreen({super.key});

  @override
  ConsumerState<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends ConsumerState<GuestScreen> {
  final _name = TextEditingController();
  GuestMode _mode = GuestMode.taste;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(guestProvider);
    final ctl = ref.read(guestProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(switch (s.stage) { GuestStage.intro => 'Pass the phone', GuestStage.play => s.mode == GuestMode.taste ? '${s.name}\'s turn' : '${s.name}: do you know me?', GuestStage.result => 'Results' })),
      body: SafeArea(
        child: switch (s.stage) {
          GuestStage.intro => _intro(s, ctl),
          GuestStage.play => _play(s, ctl),
          GuestStage.result => _result(s.result, ctl),
        },
      ),
    );
  }

  Widget _intro(GuestState s, GuestController ctl) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Hand the phone to a friend.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('They play ten cards on photos you\'ve already ranked. Nothing they do changes your ranking — it only measures how well you two agree.', style: TextStyle(color: Colors.white70, height: 1.4)),
        const SizedBox(height: 20),
        TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Their name', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        SegmentedButton<GuestMode>(
          segments: const [
            ButtonSegment(value: GuestMode.taste, label: Text('Do we agree?'), icon: Icon(Icons.handshake_rounded)),
            ButtonSegment(value: GuestMode.guess, label: Text('Do you know me?'), icon: Icon(Icons.psychology_rounded)),
          ],
          selected: {_mode},
          onSelectionChanged: (v) => setState(() => _mode = v.first),
        ),
        const SizedBox(height: 8),
        Text(
          _mode == GuestMode.taste ? 'They answer as themselves. You\'ll see where your tastes match.' : 'They try to guess what you picked. You\'ll see how well they know you.',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        if (s.tooFew) ...[
          const SizedBox(height: 12),
          const Text('Rank a few more hands first — a guest needs at least a handful of settled photos.', style: TextStyle(color: Colors.orangeAccent)),
        ],
        const SizedBox(height: 24),
        FilledButton(onPressed: () => ctl.start(_mode, _name.text), child: const Text('Start their hand')),
      ],
    );
  }

  Widget _play(GuestState s, GuestController ctl) {
    final c = s.current;
    if (c == null) return const Center(child: CircularProgressIndicator());
    final guess = s.mode == GuestMode.guess;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(children: [
            Text(
              c.kind == GuestCardKind.duel ? (guess ? 'Which one did they rank higher?' : 'Which one do you like more?') : (guess ? 'Are they feeling this one?' : 'Feeling it?'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: s.index / s.cards.length, minHeight: 4, backgroundColor: Colors.white10, color: AppTheme.accent)),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: KeyedSubtree(
              key: ValueKey(s.index),
              child: c.kind == GuestCardKind.duel
                  ? DuelCard(topId: c.a, bottomId: c.b!, mediaOf: (id) => s.mediaIds[id], onPick: ctl.pick)
                  : VibeCard(mediaId: s.mediaIds[c.a], onAnswer: ctl.vibe),
            ),
          ),
        ),
      ],
    );
  }

  Widget _result(GuestResult r, GuestController ctl) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(fit: StackFit.expand, children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: r.pct / 100),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => CircularProgressIndicator(value: v, strokeWidth: 14, backgroundColor: Colors.white10, color: AppTheme.accent, strokeCap: StrokeCap.round),
                    ),
                    Center(child: Text('${r.pct}%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800))),
                  ]),
                ),
              ).animate().scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text(GuestGame.verdict(r), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)).animate(delay: 300.ms).fadeIn(),
              const SizedBox(height: 4),
              Text('${r.name} matched you on ${r.agreed} of ${r.total} cards', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
              if (r.disagreements.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(r.mode == GuestMode.taste ? 'Where you disagree' : 'What they got wrong', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                for (final a in r.disagreements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 120,
                      child: Row(children: [
                        Expanded(child: BeatPhoto(a.card.a, borderRadius: 12, size: ThumbCacheSizes.grid, child: a.card.kind == GuestCardKind.duel ? _tag(a, a.card.a) : _vibeTag(a))),
                        if (a.card.b != null) ...[
                          const SizedBox(width: 8),
                          Expanded(child: BeatPhoto(a.card.b!, borderRadius: 12, size: ThumbCacheSizes.grid, child: _tag(a, a.card.b!))),
                        ],
                      ]),
                    ),
                  ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            IconButton.filledTonal(
              tooltip: 'Share',
              onPressed: () => SharePreviewScreen.open(context, card: _GuestShareCard(result: r), filename: 'photorank-guest.png', text: '${r.name} and I agree ${r.pct}% on my photos — PhotoRank'),
              icon: const Icon(Icons.ios_share_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(child: FilledButton(onPressed: ctl.reset, child: const Text('Play again'))),
          ]),
        ),
      ],
    );
  }

  Widget _tag(GuestAnswer a, int id) {
    final owner = a.card.ownerPick == id;
    final guest = a.pickedId == id;
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(padding: const EdgeInsets.all(6), child: Pill(owner ? 'You' : guest ? a.card.kind == GuestCardKind.duel ? 'Them' : '' : '', color: owner ? AppTheme.accent : Colors.blueGrey)),
    );
  }

  Widget _vibeTag(GuestAnswer a) => Align(
        alignment: Alignment.bottomLeft,
        child: Padding(padding: const EdgeInsets.all(6), child: Pill('You: ${a.card.ownerFeelsIt! ? '♥' : '—'} · Them: ${a.feltIt! ? '♥' : '—'}')),
      );
}

class _GuestShareCard extends StatelessWidget {
  const _GuestShareCard({required this.result});
  final GuestResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Container(
      width: 360,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: AppTheme.bg, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.mode == GuestMode.taste ? 'Do we agree?' : 'Do you know me?', style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text('${r.pct}%', style: const TextStyle(fontSize: 88, fontWeight: FontWeight.w800, color: AppTheme.accent, letterSpacing: -3, height: 1)),
          Text('${r.name} matched me on ${r.agreed} of ${r.total} photos', style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 4),
          Text(GuestGame.verdict(r), style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 14),
          const Text('Ranked with PhotoRank', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
