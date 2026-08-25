import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/dealer/photo_state.dart';
import '../../core/rating/observation.dart';
import '../../core/sampler/collections.dart';
import '../../core/sampler/moments.dart';
import '../../core/sampler/rank_sampler.dart';

class BrowseState {
  const BrowseState({
    this.channel = Channel.topShelf,
    this.items = const [],
    this.page = 0,
    this.momentLabel,
    this.loading = false,
  });

  final Channel channel;
  final List<PhotoState> items;
  final int page;

  /// Time Machine: which day is on screen.
  final String? momentLabel;
  final bool loading;

  BrowseState copyWith({
    Channel? channel,
    List<PhotoState>? items,
    int? page,
    String? momentLabel,
    bool? loading,
    bool clearMoment = false,
  }) =>
      BrowseState(
        channel: channel ?? this.channel,
        items: items ?? this.items,
        page: page ?? this.page,
        momentLabel: clearMoment ? null : (momentLabel ?? this.momentLabel),
        loading: loading ?? this.loading,
      );
}

/// Feeds the Flow: rank-weighted pages per channel, hearts, view logging.
class BrowseController extends Notifier<BrowseState> {
  static const _pageSize = 24;
  final _seen = <int>{};

  @override
  BrowseState build() => const BrowseState();

  Future<List<PhotoState>> _pool() async {
    final axis = await ref.read(axisIdProvider.future);
    return ref.read(rankingRepoProvider).photoStates(axis);
  }

  Future<void> open(Channel channel) async {
    state = BrowseState(channel: channel, loading: true);
    _seen.clear();
    await more();
  }

  /// Appends another page for sampling channels; reloads a moment for
  /// Time Machine.
  Future<void> more() async {
    final sampler = ref.read(samplerProvider);
    final pool = await _pool();
    final settled = pool.where((p) => p.observations > 0).toList();
    final source = settled.length >= 20 ? settled : pool;
    List<PhotoState> next;
    String? label;
    switch (state.channel) {
      case Channel.topShelf:
        next = sampler.topShelf(onePerMoment([...source]..sort((a, b) => b.mu.compareTo(a.mu)), keys: momentKeys(pool)), count: _pageSize, exclude: _seen);
      case Channel.wildcard:
        next = sampler.sample(pool, count: _pageSize, temperature: null, exclude: _seen);
      case Channel.deepCuts:
        next = sampler.deepCuts(source, count: _pageSize, exclude: _seen);
      case Channel.timeMachine:
        next = sampler.timeMachine(pool);
        if (next.isNotEmpty) {
          final d = next.first.takenAt!;
          label = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        }
      case Channel.rising:
        final axis = await ref.read(axisIdProvider.future);
        final movers = await ref.read(beatRepoProvider).moversSince(axis, DateTime.now().subtract(const Duration(days: 7)));
        final up = movers.where((m) => m.delta >= 3).map((m) => m.photoId).toSet();
        final risers = pool.where((p) => up.contains(p.id)).toList()..sort((a, b) => b.mu.compareTo(a.mu));
        next = risers.where((p) => !_seen.contains(p.id)).take(_pageSize).toList();
      case Channel.thisDay:
        next = thisDay(pool, DateTime.now()).where((p) => !_seen.contains(p.id)).take(_pageSize).toList();
      case Channel.collection:
        next = const [];
    }
    _seen.addAll(next.map((p) => p.id));
    final replace = state.channel == Channel.timeMachine;
    state = state.copyWith(
      items: replace ? next : [...state.items, ...next],
      page: replace ? 0 : state.page,
      momentLabel: label,
      clearMoment: label == null,
      loading: false,
    );
  }

  Future<void> onPage(int page) async {
    state = state.copyWith(page: page);
    if (page < state.items.length) {
      ref.read(photoRepoProvider).recordView(state.items[page].id, source: state.channel.name);
    }
    if (state.channel != Channel.timeMachine && page >= state.items.length - 6 && !state.loading) {
      state = state.copyWith(loading: true);
      await more();
    }
  }

  /// Open a fixed, ranked list (an auto-collection) in the Flow.
  void openCollection(Collection c, List<PhotoState> pool) {
    final byId = {for (final p in pool) p.id: p};
    final items = [for (final id in c.ids) if (byId[id] != null) byId[id]!];
    _seen
      ..clear()
      ..addAll(c.ids);
    state = BrowseState(channel: Channel.collection, items: items, momentLabel: c.title);
  }

  Future<List<Collection>> collections() async => buildCollections(await _pool());

  /// A light "feeling it" from the Flow.
  Future<void> heart(int photoId) async {
    final axis = await ref.read(axisIdProvider.future);
    await ref.read(rankingRepoProvider).applyCard(Decompose.heart(
          axisId: axis,
          cardId: 'heart-$photoId-${DateTime.now().millisecondsSinceEpoch}',
          photoId: photoId,
          now: DateTime.now(),
        ));
  }

  /// Nine rank-weighted photos for the Deal me 9 grid.
  Future<List<PhotoState>> dealNine() async {
    final pool = await _pool();
    final settled = pool.where((p) => p.observations > 0).toList();
    return ref.read(samplerProvider).sample(settled.length >= 9 ? settled : pool, count: 9);
  }
}

final browseProvider = NotifierProvider<BrowseController, BrowseState>(BrowseController.new);
