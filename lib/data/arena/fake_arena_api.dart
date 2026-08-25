import 'dart:math';
import 'dart:typed_data';

import '../../core/rating/glicko.dart';
import 'arena_api.dart';
import 'arena_models.dart';

/// In-memory Arena with a few bot players: for tests, the emulator without a
/// backend, and UI work. Same rules as the SQL (own photo never paired,
/// one entry per day, Glicko updates).
class FakeArenaApi implements ArenaApi {
  FakeArenaApi({int bots = 12, Random? rng}) : _rng = rng ?? Random(1) {
    for (var i = 0; i < bots; i++) {
      final id = 'bot$i';
      _profiles[id] = ArenaProfile(id: id, username: 'player${i + 1}');
      _entries.add(_E(id: 'e$i', userId: id, path: 'bot/$i.jpg', mu: 1500 + (_rng.nextDouble() - 0.5) * 300, rd: 120, duels: 8));
    }
  }

  final Random _rng;
  final _profiles = <String, ArenaProfile>{};
  final _entries = <_E>[];
  final _rated = <String>{};
  final _rooms = <Room>[];
  var _duelsToday = 0;
  ArenaProfile? _me;

  @override
  ArenaProfile? get me => _me;

  @override
  Future<ArenaProfile> signIn() async => _me ??= const ArenaProfile(id: 'me');

  List<_E> _pool(String? roomId) => _entries.where((e) => e.roomId == roomId && e.status == 'active').toList();

  @override
  Future<void> submit(Uint8List jpegBytes, {required DateTime takenAt, String? roomId}) async {
    if (DateTime.now().difference(takenAt) > const Duration(hours: 36)) throw StateError('photo must be taken today');
    if (_entries.any((e) => e.userId == 'me' && e.roomId == roomId && e.status == 'active')) throw StateError('already submitted today');
    _entries.add(_E(id: 'me-${roomId ?? 'g'}', userId: 'me', path: 'me/today.jpg', roomId: roomId));
  }

  bool _setDone = false;

  int _required(String? roomId) {
    if (_setDone) return _duelsToday;
    final n = _pool(roomId).where((e) => e.userId != 'me').length;
    return (n * (n - 1) ~/ 2).clamp(0, 10);
  }

  @override
  Future<ArenaStatus> status({String? roomId}) async {
    final has = _pool(roomId).any((e) => e.userId == 'me');
    final req = _required(roomId);
    return ArenaStatus(hasEntry: has, duelsToday: _duelsToday, required: req, unlocked: has && (_setDone || _duelsToday >= req), others: _pool(roomId).where((e) => e.userId != 'me').length);
  }

  bool _unlocked(String? roomId) => _pool(roomId).any((e) => e.userId == 'me') && (_setDone || _duelsToday >= _required(roomId));

  List<BoardRow> _board(String? roomId) {
    final pool = _pool(roomId)..sort((a, b) {
      final sa = a.duels >= 6, sb = b.duels >= 6;
      if (sa != sb) return sa ? -1 : 1;
      return b.mu.compareTo(a.mu);
    });
    return [
      for (final (i, e) in pool.indexed)
        BoardRow(
          rank: i + 1,
          entryId: e.id,
          userId: e.userId,
          username: _profiles[e.userId]?.username,
          storagePath: e.path,
          mu: e.mu,
          rd: e.rd,
          duels: e.duels,
          wins: e.wins,
          settled: e.duels >= 6,
          mine: e.userId == 'me',
          total: pool.length,
        ),
    ];
  }

  @override
  Future<MyEntry?> myEntry({DateTime? day, String? roomId}) async {
    if (!_unlocked(roomId)) return null;
    final row = _board(roomId).where((r) => r.mine).firstOrNull;
    if (row == null) return null;
    return MyEntry(rank: row.rank, entryId: row.entryId, storagePath: row.storagePath, mu: row.mu, duels: row.duels, wins: row.wins, settled: row.settled, total: row.total);
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    for (final e in _entries) {
      if (e.id == entryId && e.userId == 'me') e.status = 'deleted';
    }
  }

  @override
  Future<List<Pair>> nextPairs({String? roomId, int n = 10}) async {
    final pool = _pool(roomId).where((e) => e.userId != 'me').toList()..sort((a, b) => b.rd.compareTo(a.rd));
    final out = <Pair>[];
    final taken = <String>{};
    for (final a in pool) {
      if (out.length >= n || taken.contains(a.id)) continue;
      _E? best;
      for (final b in pool) {
        if (b.id == a.id || taken.contains(b.id)) continue;
        if (_rated.contains(_key(a.id, b.id))) continue;
        if (best == null || (b.mu - a.mu).abs() < (best.mu - a.mu).abs()) best = b;
      }
      if (best == null) continue;
      taken.addAll([a.id, best.id]);
      out.add(Pair(aId: a.id, bId: best.id, aPath: a.path, bPath: best.path));
    }
    return out;
  }

  String _key(String a, String b) => a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  @override
  Future<void> recordDuel({required String aId, required String bId, required String winnerId}) async {
    final a = _entries.firstWhere((e) => e.id == aId);
    final b = _entries.firstWhere((e) => e.id == bId);
    if (a.userId == 'me' || b.userId == 'me') throw StateError('cannot rate your own photo');
    if (!_pool(a.roomId).any((e) => e.userId == 'me')) throw StateError('enter a photo first');
    if (_setDone) throw StateError('you have rated your set for today');
    if (!_rated.add(_key(aId, bId))) throw StateError('pair already rated');
    final (na, nb) = Glicko.updatePair(Rating(mu: a.mu, rd: a.rd), Rating(mu: b.mu, rd: b.rd), winnerId == aId ? Outcome.win : Outcome.loss);
    a
      ..mu = na.mu
      ..rd = na.rd
      ..duels += 1
      ..wins += winnerId == aId ? 1 : 0;
    b
      ..mu = nb.mu
      ..rd = nb.rd
      ..duels += 1
      ..wins += winnerId == bId ? 1 : 0;
    _duelsToday++;
    if (_duelsToday >= _required(a.roomId)) _setDone = true;
  }

  @override
  Future<List<BoardRow>> leaderboard({DateTime? day, String? roomId, String scope = 'global', int limit = 100, int offset = 0}) async {
    if (day != null && !_isToday(day)) return _pastBoard(day);
    if (!_unlocked(roomId)) return const [];
    return _board(roomId).skip(offset).take(limit).toList();
  }

  bool _isToday(DateTime d) {
    final t = DateTime.now().toUtc();
    return d.year == t.year && d.month == t.month && d.day == t.day;
  }

  List<BoardRow> _pastBoard(DateTime day) => [
        for (var i = 0; i < 12; i++)
          BoardRow(rank: i + 1, entryId: 'p${day.day}-$i', userId: i == 4 ? 'me' : 'bot$i', username: i == 4 ? null : 'player${i + 1}', storagePath: 'bot/${(i + day.day) % 12}.jpg', mu: 1800 - i * 30, rd: 50, duels: 12, wins: 10 - i ~/ 2, settled: true, mine: i == 4, total: 12),
      ];

  @override
  Future<List<DaySummary>> days({String? roomId}) async {
    final t = DateTime.now().toUtc();
    return [
      for (var i = 1; i <= 7; i++)
        DaySummary(day: DateTime(t.year, t.month, t.day).subtract(Duration(days: i)), entries: 100 + i * 7, finalized: true, myFinalRank: i == 3 ? null : 2 + i * 3, myStoragePath: i == 3 ? null : 'bot/$i.jpg'),
    ];
  }

  @override
  Future<List<HistoryRow>> myHistory() async {
    final today = DateTime.now().toUtc();
    return [
      for (final e in _entries.where((e) => e.userId == 'me'))
        HistoryRow(day: DateTime(today.year, today.month, today.day), roomId: e.roomId, entryId: e.id, storagePath: e.path, liveRank: _board(e.roomId).firstWhere((r) => r.entryId == e.id).rank, total: _pool(e.roomId).length, duels: e.duels, wins: e.wins, status: e.status),
      for (var i = 1; i <= 5; i++)
        HistoryRow(day: DateTime(today.year, today.month, today.day).subtract(Duration(days: i)), entryId: 'h$i', storagePath: 'bot/$i.jpg', finalRank: 3 + i * 4, total: 120 + i * 9, duels: 20, wins: 12, status: 'active'),
    ];
  }

  @override
  Future<List<Room>> myRooms() async => List.of(_rooms);

  @override
  Future<Room> createRoom(String name) async {
    final r = Room(id: 'r${_rooms.length}', code: 'ABC${_rooms.length}23', name: name, ownerId: 'me');
    _rooms.add(r);
    for (var i = 0; i < 4; i++) {
      _entries.add(_E(id: '${r.id}-b$i', userId: 'bot$i', path: 'bot/$i.jpg', roomId: r.id, mu: 1500 + (_rng.nextDouble() - 0.5) * 200, rd: 150, duels: 6));
    }
    return r;
  }

  @override
  Future<Room> joinRoom(String code) async {
    final existing = _rooms.where((r) => r.code == code.toUpperCase()).firstOrNull;
    if (existing != null) return existing;
    return createRoom('Room $code');
  }

  @override
  Future<void> claimUsername(String username) async => _me = ArenaProfile(id: 'me', username: username);
  @override
  Future<void> registerDeviceToken(String token, {required String platform}) async {}
  @override
  Future<void> follow(String userId, {bool unfollow = false}) async {}
  @override
  Future<void> block(String userId) async {}
  @override
  Future<void> report(String entryId, String reason) async {}

  @override
  Future<String> imageUrl(String storagePath) async => 'fake://$storagePath';
}

class _E {
  _E({required this.id, required this.userId, required this.path, this.roomId, this.mu = 1500, this.rd = 350, this.duels = 0});
  final String id;
  final String userId;
  final String path;
  final String? roomId;
  double mu;
  double rd;
  int duels;
  int wins = 0;
  String status = 'active';
}
