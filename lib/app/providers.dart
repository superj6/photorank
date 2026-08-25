import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/beats/unlocks.dart';
import '../core/dealer/dealer.dart';
import '../core/rating/observation.dart';
import '../core/sampler/rank_sampler.dart';
import '../data/db/database.dart';
import '../data/media/library_scanner.dart';
import '../data/media/thumbs.dart';
import '../data/repo/beat_repo.dart';
import '../data/repo/photo_repo.dart';
import '../data/repo/ranking_repo.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final photoRepoProvider = Provider((ref) => PhotoRepo(ref.watch(dbProvider)));
final rankingRepoProvider = Provider((ref) => RankingRepo(ref.watch(dbProvider)));
final scannerProvider = Provider((ref) => LibraryScanner(ref.watch(photoRepoProvider)));
final thumbCacheProvider = Provider((ref) => ThumbCache());
final samplerProvider = Provider((ref) => RankSampler());
final beatRepoProvider = Provider((ref) => BeatRepo(ref.watch(dbProvider)));

const prefUnlockAll = 'unlock_all';

/// Lifetime decisions; refreshed whenever a session invalidates it.
final decisionsProvider = FutureProvider<int>((ref) => ref.watch(beatRepoProvider).decisionCount());

class UnlockAll extends Notifier<bool> {
  @override
  bool build() {
    ref.read(photoRepoProvider).pref(prefUnlockAll).then((v) => state = v == '1');
    return false;
  }

  Future<void> set(bool v) async {
    state = v;
    await ref.read(photoRepoProvider).setPref(prefUnlockAll, v ? '1' : '0');
  }
}

final unlockAllProvider = NotifierProvider<UnlockAll, bool>(UnlockAll.new);

/// Modes currently open to this user.
final unlockedModesProvider = FutureProvider<Set<GameMode>>((ref) async {
  final all = ref.watch(unlockAllProvider);
  final decisions = await ref.watch(decisionsProvider.future);
  return Unlocks.unlocked(decisions, all: all);
});

final axisIdProvider = FutureProvider<int>((ref) => ref.watch(dbProvider).defaultAxisId());

/// Live ranking on the default axis, best first.
final rankingProvider = StreamProvider<List<PhotoState>>((ref) async* {
  final axis = await ref.watch(axisIdProvider.future);
  yield* ref.watch(rankingRepoProvider).watchRanking(axis);
});

final photoRowProvider =
    FutureProvider.family<PhotoRow?, int>((ref, id) => ref.watch(photoRepoProvider).byId(id));

final libraryCountProvider = FutureProvider<int>((ref) {
  ref.watch(scanProvider); // refresh as the scan progresses
  return ref.watch(photoRepoProvider).count();
});

// ---------------------------------------------------------------------------
// Dealer settings (mode mix, hand size), persisted in prefs as JSON.

const _prefDealer = 'dealer_config';

class DealerSettings extends Notifier<DealerConfig> {
  @override
  DealerConfig build() {
    _load();
    return const DealerConfig();
  }

  Future<void> _load() async {
    final raw = await ref.read(photoRepoProvider).pref(_prefDealer);
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final weights = <GameMode, double>{
      for (final e in (json['modes'] as Map<String, dynamic>).entries)
        GameMode.values.byName(e.key): (e.value as num).toDouble(),
    };
    state = state.copyWith(modeWeights: weights, handSize: json['handSize'] as int?);
  }

  Future<void> _save() => ref.read(photoRepoProvider).setPref(
        _prefDealer,
        jsonEncode({
          'modes': {for (final e in state.modeWeights.entries) e.key.name: e.value},
          'handSize': state.handSize,
        }),
      );

  bool isEnabled(GameMode m) => (state.modeWeights[m] ?? 0) > 0;

  void setMode(GameMode m, bool enabled) {
    final defaults = const DealerConfig().modeWeights;
    final weights = {...state.modeWeights, m: enabled ? (defaults[m] ?? 1) : 0.0};
    if (weights.values.every((w) => w <= 0)) return; // keep at least one mode
    state = state.copyWith(modeWeights: weights);
    _save();
  }

  /// Only this mode on (a "single mode" session).
  void solo(GameMode m) {
    state = state.copyWith(modeWeights: {m: 1});
    _save();
  }

  void shuffleAll() {
    state = state.copyWith(modeWeights: const DealerConfig().modeWeights);
    _save();
  }

  void setHandSize(int n) {
    state = state.copyWith(handSize: n);
    _save();
  }
}

final dealerSettingsProvider = NotifierProvider<DealerSettings, DealerConfig>(DealerSettings.new);

// ---------------------------------------------------------------------------
// Library scope + scan progress.

const _prefScope = 'scan_scope';
const prefOnboarded = 'onboarded';

class ScopeSettings extends Notifier<ScanScope?> {
  @override
  ScanScope? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final raw = await ref.read(photoRepoProvider).pref(_prefScope);
    if (raw == null) return;
    state = decode(raw);
  }

  static ScanScope decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final months = json['months'] as int?;
    final albums = (json['albums'] as List?)?.cast<String>();
    return ScanScope(
      albumIds: albums?.toSet(),
      since: months == null ? null : ScanScope.lastMonths(months).since,
    );
  }

  Future<void> set({int? months, Set<String>? albumIds}) async {
    await ref.read(photoRepoProvider).setPref(
          _prefScope,
          jsonEncode({'months': months, 'albums': albumIds?.toList()}),
        );
    state = ScanScope(albumIds: albumIds, since: months == null ? null : ScanScope.lastMonths(months).since);
  }
}

final scopeProvider = NotifierProvider<ScopeSettings, ScanScope?>(ScopeSettings.new);

class ScanController extends Notifier<ScanProgress?> {
  bool _running = false;

  @override
  ScanProgress? build() => null;

  bool get running => _running;

  Future<void> start(ScanScope scope, {bool markMissing = false}) async {
    if (_running) return;
    _running = true;
    try {
      await for (final p in ref.read(scannerProvider).scan(scope, markMissing: markMissing)) {
        state = p;
      }
    } finally {
      _running = false;
    }
  }
}

final scanProvider = NotifierProvider<ScanController, ScanProgress?>(ScanController.new);
