import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../config/arena_config.dart';
import 'arena_api.dart';
import 'arena_models.dart';

class SupabaseArenaApi implements ArenaApi {
  SupabaseArenaApi(this._client);

  final SupabaseClient _client;
  final _urlCache = <String, (String, DateTime)>{};

  static Future<SupabaseArenaApi> init() async {
    await Supabase.initialize(url: ArenaConfig.url, publishableKey: ArenaConfig.anonKey);
    return SupabaseArenaApi(Supabase.instance.client);
  }

  /// Accounts are linked to a synthetic address; no mail is ever sent.
  static String recoveryEmail(String username) => '${username.toLowerCase()}@users.photorank';

  static bool _isRecoverable(User u) => (u.email ?? '').endsWith('@users.photorank');

  @override
  ArenaProfile? get me {
    final u = _client.auth.currentUser;
    return u == null ? null : ArenaProfile(id: u.id, recoverable: _isRecoverable(u));
  }

  @override
  Future<ArenaProfile> signIn() async {
    final stored = _client.auth.currentUser;
    if (stored != null) {
      // A stored session can outlive its refresh token (device clock jumps,
      // a reset dev database). Only a definitive rejection (4xx) means the
      // session is dead — a server restart, 5xx or network error must never
      // cost anyone their account. Recoverable accounts are never replaced:
      // the user restores them with their phrase instead.
      try {
        await _client.auth.getUser();
      } on AuthException catch (e) {
        final status = int.tryParse(e.statusCode ?? '');
        if (status == null || status >= 500) rethrow; // transient: keep the session
        if (_isRecoverable(stored)) throw const SessionExpired(recoverable: true);
        await _client.auth.signOut();
      }
    }
    if (_client.auth.currentUser == null) await _client.auth.signInAnonymously();
    return _profile();
  }

  Future<ArenaProfile> _profile() async {
    final u = _client.auth.currentUser!;
    final row = await _client.from('profiles').select('username, display_name').eq('id', u.id).maybeSingle();
    return ArenaProfile(id: u.id, username: row?['username'] as String?, displayName: row?['display_name'] as String?, recoverable: _isRecoverable(u));
  }

  static var _tzReady = false;

  /// Arena days roll over at midnight US Pacific time (matching the server's
  /// arena_today()); explicit dates from history rows pass through as labels.
  String _day(DateTime? d) {
    DateTime t;
    if (d != null) {
      t = d;
    } else {
      if (!_tzReady) {
        tzdata.initializeTimeZones();
        _tzReady = true;
      }
      t = tz.TZDateTime.now(tz.getLocation('America/Los_Angeles'));
    }
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> submit(Uint8List jpegBytes, {required DateTime takenAt, String? roomId}) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${_day(null)}-${roomId ?? 'global'}-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from(ArenaConfig.bucket).uploadBinary(path, jpegBytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    try {
      await _client.rpc('submit_entry', params: {'p_room': roomId, 'p_storage_path': path, 'p_taken_at': takenAt.toUtc().toIso8601String()});
    } catch (e) {
      await _client.storage.from(ArenaConfig.bucket).remove([path]);
      rethrow;
    }
  }

  @override
  Future<ArenaStatus> status({String? roomId}) async {
    final rows = await _client.rpc('arena_status', params: {'p_room': roomId}) as List;
    return rows.isEmpty ? ArenaStatus.none : ArenaStatus.fromJson((rows.first as Map).cast<String, dynamic>());
  }

  @override
  Future<MyEntry?> myEntry({DateTime? day, String? roomId}) async {
    final rows = await _client.rpc('my_entry', params: {'p_day': _day(day), 'p_room': roomId}) as List;
    return rows.isEmpty ? null : MyEntry.fromJson((rows.first as Map).cast<String, dynamic>());
  }

  @override
  Future<void> deleteEntry(String entryId) => _client.rpc('delete_entry', params: {'p_entry': entryId});

  @override
  Future<List<Pair>> nextPairs({String? roomId, int n = 10}) async {
    final rows = await _client.rpc('next_pairs', params: {'p_room': roomId, 'p_n': n}) as List;
    return [for (final r in rows) Pair.fromJson((r as Map).cast<String, dynamic>())];
  }

  @override
  Future<void> recordDuel({required String aId, required String bId, required String winnerId}) =>
      _client.rpc('record_duel', params: {'p_a': aId, 'p_b': bId, 'p_winner': winnerId});

  @override
  Future<List<BoardRow>> leaderboard({DateTime? day, String? roomId, String scope = 'global', int limit = 100, int offset = 0}) async {
    final rows = await _client.rpc('leaderboard', params: {'p_day': _day(day), 'p_room': roomId, 'p_scope': scope, 'p_limit': limit, 'p_offset': offset}) as List;
    return [for (final r in rows) BoardRow.fromJson((r as Map).cast<String, dynamic>())];
  }

  @override
  Future<List<HistoryRow>> myHistory() async {
    final rows = await _client.rpc('my_history') as List;
    return [for (final r in rows) HistoryRow.fromJson((r as Map).cast<String, dynamic>())];
  }

  @override
  Future<List<DaySummary>> days({String? roomId}) async {
    final rows = await _client.rpc('arena_days', params: {'p_room': roomId}) as List;
    return [for (final r in rows) DaySummary.fromJson((r as Map).cast<String, dynamic>())];
  }

  @override
  Future<List<Room>> myRooms() async {
    final rows = await _client.rpc('my_rooms') as List;
    return [for (final r in rows) Room.fromJson((r as Map).cast<String, dynamic>())];
  }

  @override
  Future<Room> createRoom(String name) async =>
      Room.fromJson(((await _client.rpc('create_room', params: {'p_name': name})) as Map).cast<String, dynamic>());

  @override
  Future<Room> joinRoom(String code) async =>
      Room.fromJson(((await _client.rpc('join_room', params: {'p_code': code})) as Map).cast<String, dynamic>());

  @override
  Future<void> claimUsername(String username, {String? recoveryPhrase}) async {
    final u = _client.auth.currentUser!;
    final linked = _isRecoverable(u);
    if (!linked && recoveryPhrase == null) throw StateError('A username needs a recovery phrase.');
    // Link (or re-point) the account first: if the name is taken this fails
    // with a clear error before anything else changes.
    await _client.auth.updateUser(UserAttributes(email: recoveryEmail(username), password: linked ? null : recoveryPhrase));
    try {
      await _client.rpc('claim_username', params: {'p_username': username});
    } catch (e) {
      if (u.email != null) await _client.auth.updateUser(UserAttributes(email: u.email)); // roll the link back
      rethrow;
    }
  }

  @override
  Future<ArenaProfile> restore(String username, String recoveryPhrase) async {
    await _client.auth.signInWithPassword(email: recoveryEmail(username), password: recoveryPhrase);
    return _profile();
  }

  @override
  Future<void> setRecoveryPhrase(String recoveryPhrase) => _client.auth.updateUser(UserAttributes(password: recoveryPhrase));

  @override
  Future<void> deleteAccount() async {
    // Files first (only the account itself may delete them), then the row
    // cascade, then drop the now-dead local session.
    final paths = [for (final p in await _client.rpc('my_storage_paths') as List) p as String];
    if (paths.isNotEmpty) await _client.storage.from(ArenaConfig.bucket).remove(paths);
    await _client.rpc('delete_account');
    await _client.auth.signOut();
  }

  @override
  Future<void> registerDeviceToken(String token, {required String platform}) =>
      _client.rpc('register_device_token', params: {'p_token': token, 'p_platform': platform});

  @override
  Future<void> follow(String userId, {bool unfollow = false}) async {
    final me = _client.auth.currentUser!.id;
    if (unfollow) {
      await _client.from('follows').delete().match({'follower_id': me, 'followee_id': userId});
    } else {
      await _client.from('follows').upsert({'follower_id': me, 'followee_id': userId}, ignoreDuplicates: true);
    }
  }

  @override
  Future<void> block(String userId) async {
    final me = _client.auth.currentUser!.id;
    await _client.from('blocks').upsert({'blocker_id': me, 'blocked_id': userId}, ignoreDuplicates: true);
  }

  @override
  Future<void> report(String entryId, String reason) async {
    final me = _client.auth.currentUser!.id;
    await _client.from('reports').upsert({'entry_id': entryId, 'reporter_id': me, 'reason': reason}, ignoreDuplicates: true);
  }

  @override
  Future<String> imageUrl(String storagePath) async {
    final cached = _urlCache[storagePath];
    if (cached != null && cached.$2.isAfter(DateTime.now())) return cached.$1;
    final url = await _client.storage.from(ArenaConfig.bucket).createSignedUrl(storagePath, 3600);
    _urlCache[storagePath] = (url, DateTime.now().add(const Duration(minutes: 50)));
    return url;
  }

  // --- sets ---

  Map<String, dynamic> _row(Object? r) => (r as Map).cast<String, dynamic>();
  List<Map<String, dynamic>> _rows(Object? r) => [for (final x in r as List) _row(x)];

  @override
  Future<SetSummary> publishSet({required String title, required List<SetUploadItem> items, String visibility = 'friends'}) async {
    final uid = _client.auth.currentUser!.id;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final paths = <String>[];
    try {
      for (final (i, item) in items.indexed) {
        final path = '$uid/set/$stamp-${i + 1}.jpg';
        await _client.storage.from(ArenaConfig.bucket).uploadBinary(path, Uint8List.fromList(item.bytes), fileOptions: const FileOptions(contentType: 'image/jpeg'));
        paths.add(path);
      }
      // Remember the old files so they can be removed once the new set is live.
      final old = await _mySetPaths();
      await _client.rpc('publish_set', params: {
        'p_title': title,
        'p_visibility': visibility,
        'p_items': [for (final (i, p) in paths.indexed) {'storage_path': p, 'taken_at': items[i].takenAt?.toUtc().toIso8601String()}],
      });
      if (old.isNotEmpty) await _client.storage.from(ArenaConfig.bucket).remove(old);
    } catch (e) {
      if (paths.isNotEmpty) await _client.storage.from(ArenaConfig.bucket).remove(paths);
      rethrow;
    }
    return (await visibleSets()).firstWhere((s) => s.mine);
  }

  Future<List<String>> _mySetPaths() async {
    final uid = _client.auth.currentUser!.id;
    final set = await _client.from('sets').select('id').eq('owner_id', uid).maybeSingle();
    if (set == null) return const [];
    final rows = await _client.from('set_items').select('storage_path').eq('set_id', set['id'] as String);
    return [for (final r in rows) r['storage_path'] as String];
  }

  @override
  Future<void> unpublishSet() async {
    final old = await _mySetPaths();
    await _client.rpc('unpublish_set');
    if (old.isNotEmpty) await _client.storage.from(ArenaConfig.bucket).remove(old);
  }

  @override
  Future<void> setVisibility(String visibility) => _client.rpc('set_visibility', params: {'p_visibility': visibility});

  @override
  Future<List<SetSummary>> visibleSets() async {
    final me = _client.auth.currentUser!.id;
    return [for (final r in _rows(await _client.rpc('visible_sets'))) SetSummary.fromJson(r, me: me)];
  }

  @override
  Future<SetSummary> joinSet(String code) async {
    final id = await _client.rpc('join_set', params: {'p_code': code.trim()}) as String;
    return (await visibleSets()).firstWhere((s) => s.id == id);
  }

  @override
  Future<List<Pair>> setNextPairs(String setId, {int n = 10}) async =>
      [for (final r in _rows(await _client.rpc('set_next_pairs', params: {'p_set': setId, 'p_n': n}))) Pair.fromJson(r)];

  @override
  Future<void> setRecordDuel({required String setId, required String aId, required String bId, required String winnerId}) =>
      _client.rpc('set_record_duel', params: {'p_set': setId, 'p_a': aId, 'p_b': bId, 'p_winner': winnerId});

  @override
  Future<List<SetBoardRow>> setBoard(String setId, {String? raterId}) async =>
      [for (final r in _rows(await _client.rpc('set_board', params: {'p_set': setId, 'p_rater': raterId}))) SetBoardRow.fromJson(r)];

  @override
  Future<List<SetRater>> setRaters(String setId) async =>
      [for (final r in _rows(await _client.rpc('set_raters', params: {'p_set': setId}))) SetRater.fromJson(r)];

  @override
  Future<FriendRow?> findProfile(String username) async {
    final rows = _rows(await _client.rpc('find_profile', params: {'p_username': username}));
    return rows.isEmpty ? null : FriendRow.fromJson(rows.first);
  }

  @override
  Future<List<FriendRow>> myFriends() async => [for (final r in _rows(await _client.rpc('my_friends'))) FriendRow.fromJson(r)];
}
