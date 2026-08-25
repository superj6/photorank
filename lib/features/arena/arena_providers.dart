
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../app/providers.dart';
import '../../config/arena_config.dart';
import '../../data/arena/arena_api.dart';
import '../../data/arena/arena_models.dart';
import '../../data/arena/fake_arena_api.dart';
import '../../data/arena/prepare_upload.dart';
import '../../data/arena/supabase_arena_api.dart';

/// Null when Arena is not configured in a release build. Debug builds fall
/// back to the in-memory fake so the UI can be developed without a backend.
final arenaApiProvider = FutureProvider<ArenaApi?>((ref) async {
  if (ArenaConfig.configured) return SupabaseArenaApi.init();
  if (kDebugMode) return FakeArenaApi();
  return null;
});

const prefArenaConsent = 'arena_consent';

class ArenaState {
  const ArenaState({
    this.profile,
    this.roomId,
    this.rooms = const [],
    this.myEntry,
    this.board = const [],
    this.duelsToday = 0,
    this.loading = true,
    this.error,
    this.consent = false,
    this.busy = false,
    this.scope = 'global',
  });

  final ArenaProfile? profile;
  final String? roomId; // null = global
  final List<Room> rooms;
  final MyEntry? myEntry;
  final List<BoardRow> board;
  final int duelsToday;
  final bool loading;
  final String? error;
  final bool consent;
  final bool busy;

  /// 'global' or 'friends' (people you follow + you).
  final String scope;

  bool get canPlay => board.length >= 2 && duelsToday < ArenaConfig.maxDuelsPerDay;
  Room? get room => rooms.where((r) => r.id == roomId).firstOrNull;

  ArenaState copyWith({
    ArenaProfile? profile,
    String? roomId,
    bool clearRoom = false,
    List<Room>? rooms,
    MyEntry? myEntry,
    bool clearEntry = false,
    List<BoardRow>? board,
    int? duelsToday,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? consent,
    bool? busy,
    String? scope,
  }) =>
      ArenaState(
        profile: profile ?? this.profile,
        roomId: clearRoom ? null : (roomId ?? this.roomId),
        rooms: rooms ?? this.rooms,
        myEntry: clearEntry ? null : (myEntry ?? this.myEntry),
        board: board ?? this.board,
        duelsToday: duelsToday ?? this.duelsToday,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        consent: consent ?? this.consent,
        busy: busy ?? this.busy,
        scope: scope ?? this.scope,
      );
}

class ArenaController extends Notifier<ArenaState> {
  @override
  ArenaState build() => const ArenaState();

  Future<ArenaApi?> get _api => ref.read(arenaApiProvider.future);

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = await _api;
      if (api == null) {
        state = state.copyWith(loading: false, error: 'Arena is not available in this build.');
        return;
      }
      final profile = await api.signIn();
      final consent = (await ref.read(photoRepoProvider).pref(prefArenaConsent)) == '1';
      final rooms = await api.myRooms();
      state = state.copyWith(profile: profile, rooms: rooms, consent: consent);
      await refresh();
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
    }
  }

  Future<void> refresh() async {
    final api = await _api;
    if (api == null) return;
    try {
      final entry = await api.myEntry(roomId: state.roomId);
      final board = await api.leaderboard(roomId: state.roomId, scope: state.scope);
      final duels = await api.myDuelsToday(roomId: state.roomId);
      state = state.copyWith(myEntry: entry, clearEntry: entry == null, board: board, duelsToday: duels, loading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
    }
  }

  Future<void> setScope(String scope) async {
    state = state.copyWith(scope: scope, loading: true);
    await refresh();
  }

  Future<void> follow(String userId, {bool unfollow = false}) async {
    await (await _api)?.follow(userId, unfollow: unfollow);
    if (state.scope == 'friends') await refresh();
  }

  Future<void> selectRoom(String? roomId) async {
    state = state.copyWith(roomId: roomId, clearRoom: roomId == null, loading: true);
    await refresh();
  }

  Future<void> acceptConsent() async {
    await ref.read(photoRepoProvider).setPref(prefArenaConsent, '1');
    state = state.copyWith(consent: true);
  }

  /// Uploads the chosen local photo (by DB id) as today's entry.
  Future<bool> submit(int photoId) async {
    final api = await _api;
    if (api == null) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final row = await ref.read(photoRepoProvider).byId(photoId);
      final entity = row == null ? null : await AssetEntity.fromId(row.mediaId);
      final bytes = await entity?.originBytes;
      if (bytes == null) throw StateError('Could not read that photo.');
      final prepared = await compute(_prepare, bytes);
      if (prepared == null) throw StateError('That file is not an image.');
      await api.submit(prepared.bytes, roomId: state.roomId);
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(error: _msg(e));
      return false;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<void> deleteMyEntry() async {
    final api = await _api;
    final e = state.myEntry;
    if (api == null || e == null) return;
    await api.deleteEntry(e.entryId);
    await refresh();
  }

  Future<List<Pair>> startRound() async {
    final api = await _api;
    if (api == null) return const [];
    final left = ArenaConfig.maxDuelsPerDay - state.duelsToday;
    return api.nextPairs(roomId: state.roomId, n: left.clamp(0, ArenaConfig.duelsPerRound));
  }

  Future<void> recordDuel(Pair p, String winnerId) async {
    final api = await _api;
    if (api == null) return;
    await api.recordDuel(aId: p.aId, bId: p.bId, winnerId: winnerId);
    state = state.copyWith(duelsToday: state.duelsToday + 1);
  }

  Future<Room?> createRoom(String name) async {
    final api = await _api;
    if (api == null) return null;
    final r = await api.createRoom(name);
    state = state.copyWith(rooms: [...state.rooms, r]);
    await selectRoom(r.id);
    return r;
  }

  Future<Room?> joinRoom(String code) async {
    final api = await _api;
    if (api == null) return null;
    try {
      final r = await api.joinRoom(code);
      if (!state.rooms.any((x) => x.id == r.id)) state = state.copyWith(rooms: [...state.rooms, r]);
      await selectRoom(r.id);
      return r;
    } catch (e) {
      state = state.copyWith(error: _msg(e));
      return null;
    }
  }

  Future<void> claimUsername(String username) async {
    final api = await _api;
    if (api == null) return;
    try {
      await api.claimUsername(username);
      state = state.copyWith(profile: ArenaProfile(id: state.profile!.id, username: username.toLowerCase()));
    } catch (e) {
      state = state.copyWith(error: _msg(e));
    }
  }

  Future<void> report(String entryId) async => (await _api)?.report(entryId, 'inappropriate');
  Future<void> block(String userId) async {
    await (await _api)?.block(userId);
    await refresh();
  }

  static String _msg(Object e) {
    final s = e.toString();
    final m = RegExp(r'message: ([^,}]+)').firstMatch(s);
    return (m?.group(1) ?? s.replaceFirst('Bad state: ', '').replaceFirst('Exception: ', '')).trim();
  }
}

PreparedUpload? _prepare(Uint8List bytes) => prepareUpload(bytes);

final arenaProvider = NotifierProvider<ArenaController, ArenaState>(ArenaController.new);

/// Signed/loadable URL for a storage path.
final arenaImageUrlProvider = FutureProvider.family<String?, String>((ref, path) async {
  final api = await ref.watch(arenaApiProvider.future);
  return api?.imageUrl(path);
});
