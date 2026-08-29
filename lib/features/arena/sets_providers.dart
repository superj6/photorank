import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/arena/arena_api.dart';
import '../../data/arena/arena_models.dart';
import '../../data/arena/prepare_upload.dart';
import 'arena_providers.dart';

/// Published Top-N sets: yours, and the ones friends let you see.
class SetsState {
  const SetsState({this.sets = const [], this.loading = true, this.busy = false, this.progress, this.error});
  final List<SetSummary> sets;
  final bool loading;
  final bool busy;

  /// Upload progress while publishing: (done, total).
  final (int, int)? progress;
  final String? error;

  SetSummary? get mine => sets.where((s) => s.mine).firstOrNull;
  List<SetSummary> get friends => sets.where((s) => !s.mine).toList();

  SetsState copyWith({List<SetSummary>? sets, bool? loading, bool? busy, (int, int)? progress, bool clearProgress = false, String? error, bool clearError = false}) => SetsState(
        sets: sets ?? this.sets,
        loading: loading ?? this.loading,
        busy: busy ?? this.busy,
        progress: clearProgress ? null : (progress ?? this.progress),
        error: clearError ? null : (error ?? this.error),
      );
}

class SetsController extends Notifier<SetsState> {
  @override
  SetsState build() => const SetsState();

  /// The signed-in API, or null when Arena is unavailable in this build.
  Future<ArenaApi?> _api() async {
    final api = await ref.read(arenaApiProvider.future);
    if (api == null) return null;
    if (ref.read(arenaProvider).profile == null) await ref.read(arenaProvider.notifier).load();
    return api;
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: state.sets.isEmpty, clearError: true);
    try {
      final api = await _api();
      if (api == null) {
        state = state.copyWith(loading: false, error: 'Arena is not available in this build.');
        return;
      }
      state = state.copyWith(sets: await api.visibleSets(), loading: false);
      // Boards and rater lists are cached per set; a refresh must drop them too.
      ref.invalidate(setRatersProvider);
      ref.invalidate(setBoardProvider);
    } catch (e) {
      state = state.copyWith(loading: false, error: ArenaController.msg(e));
    }
  }

  /// Downsizes and strips each photo (by DB id, in rank order) and publishes
  /// them as your set. Returns false (with [SetsState.error]) on failure.
  Future<bool> publish({required List<int> photoIds, required String title, required String visibility}) async {
    final api = await _api();
    if (api == null) return false;
    state = state.copyWith(busy: true, progress: (0, photoIds.length), clearError: true);
    try {
      final repo = ref.read(photoRepoProvider);
      final source = ref.read(photoSourceProvider);
      final items = <SetUploadItem>[];
      for (final (i, id) in photoIds.indexed) {
        final row = await repo.byId(id);
        final bytes = row == null ? null : await source.originalBytes(row.mediaId);
        if (bytes == null) throw StateError('Could not read one of the photos.');
        final prepared = await compute(_prepare, bytes);
        if (prepared == null) throw StateError('One of the files is not an image.');
        items.add(SetUploadItem(bytes: prepared.bytes, takenAt: row!.takenAt));
        state = state.copyWith(progress: (i + 1, photoIds.length));
      }
      await api.publishSet(title: title, items: items, visibility: visibility);
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: ArenaController.msg(e));
      return false;
    } finally {
      state = state.copyWith(busy: false, clearProgress: true);
    }
  }

  Future<void> unpublish() async {
    final api = await _api();
    if (api == null) return;
    state = state.copyWith(busy: true);
    try {
      await api.unpublishSet();
      await refresh();
    } catch (e) {
      state = state.copyWith(error: ArenaController.msg(e));
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> setVisibility(String visibility) async {
    final api = await _api();
    if (api == null) return;
    try {
      await api.setVisibility(visibility);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: ArenaController.msg(e));
    }
  }

  Future<SetSummary?> join(String code) async {
    final api = await _api();
    if (api == null) return null;
    try {
      final s = await api.joinSet(code);
      await refresh();
      return s;
    } catch (e) {
      state = state.copyWith(error: ArenaController.msg(e));
      return null;
    }
  }

  Future<List<Pair>> nextPairs(SetSummary set) async {
    final api = await _api();
    if (api == null) return const [];
    final left = set.requiredDuels - set.myDuels;
    if (left <= 0) return const [];
    return api.setNextPairs(set.id, n: left.clamp(1, 10));
  }

  Future<void> recordDuel(SetSummary set, Pair p, String winnerId) async {
    final api = await _api();
    if (api == null) return;
    await api.setRecordDuel(setId: set.id, aId: p.aId, bId: p.bId, winnerId: winnerId);
    state = state.copyWith(sets: [
      for (final s in state.sets)
        if (s.id == set.id)
          SetSummary(
            id: s.id,
            ownerId: s.ownerId,
            ownerUsername: s.ownerUsername,
            title: s.title,
            visibility: s.visibility,
            linkCode: s.linkCode,
            items: s.items,
            updatedAt: s.updatedAt,
            myDone: s.myDuels + 1 >= s.requiredDuels,
            myDuels: s.myDuels + 1,
            raters: s.raters,
            mine: s.mine,
          )
        else
          s,
    ]);
  }

  Future<void> follow(String userId, {bool unfollow = false}) async {
    final api = await _api();
    try {
      await api?.follow(userId, unfollow: unfollow);
    } catch (e) {
      state = state.copyWith(error: ArenaController.msg(e));
    }
    ref.invalidate(friendsProvider);
    await refresh();
  }
}

PreparedUpload? _prepare(Uint8List bytes) => prepareUpload(bytes);

/// The caller's arena user id (for "my board" lookups).
final setsMeIdProvider = Provider<String?>((ref) => ref.watch(arenaProvider).profile?.id);

final setsProvider = NotifierProvider<SetsController, SetsState>(SetsController.new);

final friendsProvider = FutureProvider.autoDispose<List<FriendRow>>((ref) async {
  final api = await ref.watch(arenaApiProvider.future);
  if (api == null) return const [];
  if (api.me == null) await api.signIn();
  return api.myFriends();
});

/// (setId, raterId) → board. raterId null = the pooled aggregate.
final setBoardProvider = FutureProvider.autoDispose.family<List<SetBoardRow>, (String, String?)>((ref, key) async {
  final api = await ref.watch(arenaApiProvider.future);
  return api?.setBoard(key.$1, raterId: key.$2) ?? const [];
});

final setRatersProvider = FutureProvider.autoDispose.family<List<SetRater>, String>((ref, setId) async {
  final api = await ref.watch(arenaApiProvider.future);
  return api?.setRaters(setId) ?? const [];
});
