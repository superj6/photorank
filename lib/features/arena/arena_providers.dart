
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/notifications.dart';
import '../../app/providers.dart';
import '../../app/push.dart';
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
const prefArenaReminder = 'notify_arena';
const prefArenaReminderHour = 'notify_arena_hour';

class ArenaState {
  const ArenaState({
    this.profile,
    this.roomId,
    this.rooms = const [],
    this.myEntry,
    this.board = const [],
    this.status = ArenaStatus.none,
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
  final ArenaStatus status;
  final bool loading;
  final String? error;
  final bool consent;
  final bool busy;

  /// 'global' or 'friends' (people you follow + you).
  final String scope;

  /// Entered today but the set is not rated yet (and there is something to rate).
  bool get needsToRate => status.hasEntry && !status.unlocked && status.left > 0;
  Room? get room => rooms.where((r) => r.id == roomId).firstOrNull;

  ArenaState copyWith({
    ArenaProfile? profile,
    String? roomId,
    bool clearRoom = false,
    List<Room>? rooms,
    MyEntry? myEntry,
    bool clearEntry = false,
    List<BoardRow>? board,
    ArenaStatus? status,
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
        status: status ?? this.status,
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
      Push.register(api);
    } catch (e) {
      state = state.copyWith(loading: false, error: _msg(e));
    }
  }

  Future<void> refresh() async {
    final api = await _api;
    if (api == null) return;
    try {
      final status = await api.status(roomId: state.roomId);
      final entry = status.unlocked ? await api.myEntry(roomId: state.roomId) : null;
      final board = status.unlocked ? await api.leaderboard(roomId: state.roomId, scope: state.scope) : const <BoardRow>[];
      state = state.copyWith(status: status, myEntry: entry, clearEntry: entry == null, board: board, loading: false, clearError: true);
      if (status.hasEntry && state.roomId == null) _skipNudgeToday();
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

  /// Uploads the chosen local photo (by DB id) as today's entry. The photo
  /// must have been taken today (the server checks the capture time too).
  Future<bool> submit(int photoId) async {
    final api = await _api;
    if (api == null) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final row = await ref.read(photoRepoProvider).byId(photoId);
      final takenAt = row?.takenAt;
      if (row == null || takenAt == null) throw StateError('That photo has no capture date.');
      if (!isFromToday(takenAt)) throw StateError('Only a photo taken today can enter.');
      final bytes = await ref.read(photoSourceProvider).originalBytes(row.mediaId);
      if (bytes == null) throw StateError('Could not read that photo.');
      final prepared = await compute(_prepare, bytes);
      if (prepared == null) throw StateError('That file is not an image.');
      await api.submit(prepared.bytes, takenAt: takenAt, roomId: state.roomId);
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

  /// The set to rate: what is still owed, as disjoint pairs. Called again
  /// when a page of pairs runs out (small pools pair fewer per call).
  Future<List<Pair>> nextPairs() async {
    final api = await _api;
    if (api == null) return const [];
    final left = state.status.left;
    if (left <= 0) return const [];
    return api.nextPairs(roomId: state.roomId, n: left.clamp(1, ArenaConfig.duelsPerSet));
  }

  Future<void> recordDuel(Pair p, String winnerId) async {
    final api = await _api;
    if (api == null) return;
    await api.recordDuel(aId: p.aId, bId: p.bId, winnerId: winnerId);
    final st = state.status;
    state = state.copyWith(status: ArenaStatus(hasEntry: st.hasEntry, duelsToday: st.duelsToday + 1, required: st.required, unlocked: st.hasEntry && st.duelsToday + 1 >= st.required, others: st.others));
  }

  Future<List<DaySummary>> days() async => (await _api)?.days(roomId: state.roomId) ?? const [];
  Future<List<BoardRow>> boardFor(DateTime day) async => (await _api)?.leaderboard(day: day, roomId: state.roomId) ?? const [];

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

  Future<void> _skipNudgeToday() async {
    final prefs = ref.read(photoRepoProvider);
    if (await prefs.pref(prefArenaReminder) != '1') return;
    final hour = int.tryParse(await prefs.pref(prefArenaReminderHour) ?? '') ?? 18;
    await Notifications.setArenaReminder(true, hour: hour, skipToday: true);
  }

  static String msg(Object e) => _msg(e);

  static String _msg(Object e) {
    final s = e.toString();
    final m = RegExp(r'message: ([^,}]+)').firstMatch(s);
    return (m?.group(1) ?? s.replaceFirst('Bad state: ', '').replaceFirst('Exception: ', '')).trim();
  }
}

PreparedUpload? _prepare(Uint8List bytes) => prepareUpload(bytes);

/// "Today" in the user's local calendar (the server allows 36 h of slack).
bool isFromToday(DateTime takenAt, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final t = takenAt.toLocal();
  return t.year == n.year && t.month == n.month && t.day == n.day;
}

final arenaProvider = NotifierProvider<ArenaController, ArenaState>(ArenaController.new);

/// Signed/loadable URL for a storage path.
final arenaImageUrlProvider = FutureProvider.family<String?, String>((ref, path) async {
  final api = await ref.watch(arenaApiProvider.future);
  return api?.imageUrl(path);
});
