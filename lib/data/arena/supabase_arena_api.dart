import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  ArenaProfile? get me {
    final u = _client.auth.currentUser;
    return u == null ? null : ArenaProfile(id: u.id);
  }

  @override
  Future<ArenaProfile> signIn() async {
    if (_client.auth.currentUser != null) {
      // A stored session can outlive its account (purged, or a reset dev
      // database). Verify it; if the server no longer knows us, start fresh.
      try {
        await _client.auth.getUser();
      } on AuthException {
        await _client.auth.signOut();
      }
    }
    if (_client.auth.currentUser == null) await _client.auth.signInAnonymously();
    final u = _client.auth.currentUser!;
    final row = await _client.from('profiles').select('username, display_name').eq('id', u.id).maybeSingle();
    return ArenaProfile(id: u.id, username: row?['username'] as String?, displayName: row?['display_name'] as String?);
  }

  String _day(DateTime? d) {
    final t = (d ?? DateTime.now().toUtc());
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
  Future<void> claimUsername(String username) => _client.rpc('claim_username', params: {'p_username': username});

  @override
  Future<void> follow(String userId, {bool unfollow = false}) async {
    final me = _client.auth.currentUser!.id;
    if (unfollow) {
      await _client.from('follows').delete().match({'follower_id': me, 'followee_id': userId});
    } else {
      await _client.from('follows').upsert({'follower_id': me, 'followee_id': userId});
    }
  }

  @override
  Future<void> block(String userId) async {
    final me = _client.auth.currentUser!.id;
    await _client.from('blocks').upsert({'blocker_id': me, 'blocked_id': userId});
  }

  @override
  Future<void> report(String entryId, String reason) async {
    final me = _client.auth.currentUser!.id;
    await _client.from('reports').upsert({'entry_id': entryId, 'reporter_id': me, 'reason': reason});
  }

  @override
  Future<String> imageUrl(String storagePath) async {
    final cached = _urlCache[storagePath];
    if (cached != null && cached.$2.isAfter(DateTime.now())) return cached.$1;
    final url = await _client.storage.from(ArenaConfig.bucket).createSignedUrl(storagePath, 3600);
    _urlCache[storagePath] = (url, DateTime.now().add(const Duration(minutes: 50)));
    return url;
  }
}
