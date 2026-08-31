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
    if (DateTime.now().difference(takenAt) > const Duration(hours: 26)) throw StateError('photo must be taken today (Pacific time)');
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

  final _linked = <String, (String phrase, ArenaProfile profile)>{}; // username -> phrase + account

  @override
  Future<void> claimUsername(String username, {String? recoveryPhrase}) async {
    final me = _me!;
    if (!me.recoverable && recoveryPhrase == null) throw StateError('A username needs a recovery phrase.');
    if (_profiles.values.any((p) => p.username == username) || (_linked.containsKey(username) && _linked[username]!.$2.id != me.id)) throw StateError('username taken');
    final phrase = recoveryPhrase ?? _linked.values.firstWhere((e) => e.$2.id == me.id).$1;
    _linked.removeWhere((_, e) => e.$2.id == me.id);
    _me = me.copyWith(username: username, recoverable: true);
    _linked[username] = (phrase, _me!);
  }

  @override
  Future<ArenaProfile> restore(String username, String recoveryPhrase) async {
    final e = _linked[username];
    if (e == null || e.$1 != recoveryPhrase) throw StateError('Invalid login credentials');
    return _me = e.$2;
  }

  @override
  Future<void> deleteAccount() async {
    _entries.removeWhere((e) => e.userId == 'me');
    _sets.removeWhere((s) => s.ownerId == 'me');
    _linked.removeWhere((_, e) => e.$2.id == 'me');
    _me = null;
  }

  @override
  Future<void> setRecoveryPhrase(String recoveryPhrase) async {
    final me = _me!;
    if (!me.recoverable) throw StateError('claim a username first');
    _linked[me.username!] = (recoveryPhrase, me);
  }
  @override
  Future<void> registerDeviceToken(String token, {required String platform}) async {}
  @override
  Future<void> block(String userId) async {}
  @override
  Future<void> report(String entryId, String reason) async {}

  @override
  Future<String> imageUrl(String storagePath) async => 'fake://$storagePath';

  // --- sets: one friend ("player2") has a published set; yours is in memory ---

  final _sets = <_Set>[];
  final _friends = <String, (bool, bool)>{'bot1': (true, true), 'bot2': (true, false), 'bot3': (false, true)};
  var _seeded = false;

  void _seedSets() {
    if (_seeded) return;
    _seeded = true;
    final s = _Set(id: 'set-bot1', ownerId: 'bot1', title: 'Player 2\'s summer', visibility: 'friends', code: 'FRIEND01');
    for (var i = 1; i <= 8; i++) {
      s.items.add(_Item(id: 'set-bot1-$i', path: 'bot1/set/$i.jpg', ownerRank: i));
    }
    _sets.add(s);
  }

  _Set? get _mySet => _sets.where((s) => s.ownerId == 'me').firstOrNull;

  @override
  Future<SetSummary> publishSet({required String title, required List<SetUploadItem> items, String visibility = 'friends'}) async {
    _seedSets();
    if (_me?.username == null) throw StateError('claim a username first');
    if (items.length < 3 || items.length > 50) throw StateError('a set has 3 to 50 photos');
    _sets.removeWhere((s) => s.ownerId == 'me');
    final s = _Set(id: 'set-me', ownerId: 'me', title: title, visibility: visibility, code: 'MYSET123');
    for (final (i, it) in items.indexed) {
      s.items.add(_Item(id: 'set-me-${i + 1}', path: 'me/set/${i + 1}.jpg', ownerRank: i + 1, takenAt: it.takenAt));
    }
    _sets.add(s);
    // A couple of bots rate it straight away so the owner has boards to look at.
    for (final bot in ['bot1', 'bot3']) {
      final ratings = s.ratingsFor(bot);
      for (var k = 0; k < s.required; k++) {
        final a = s.items[_rng.nextInt(s.items.length)];
        var b = s.items[_rng.nextInt(s.items.length)];
        if (a == b) continue;
        final winner = _rng.nextDouble() < 0.7 ? (a.ownerRank < b.ownerRank ? a : b) : (a.ownerRank < b.ownerRank ? b : a);
        s.duel(bot, a, b, winner, ratings);
      }
      s.done.add(bot);
    }
    return _summary(s);
  }

  @override
  Future<void> unpublishSet() async => _sets.removeWhere((s) => s.ownerId == 'me');

  @override
  Future<void> setVisibility(String visibility) async => _mySet?.visibility = visibility;

  SetSummary _summary(_Set s) => SetSummary(
        id: s.id,
        ownerId: s.ownerId,
        ownerUsername: s.ownerId == 'me' ? _me?.username : _profiles[s.ownerId]?.username,
        title: s.title,
        visibility: s.visibility,
        linkCode: s.ownerId == 'me' ? s.code : null,
        items: s.items.length,
        updatedAt: DateTime.now(),
        myDone: s.done.contains('me'),
        myDuels: s.duels.where((d) => d.rater == 'me').length,
        raters: s.done.length,
        mine: s.ownerId == 'me',
      );

  @override
  Future<List<SetSummary>> visibleSets() async {
    _seedSets();
    return [for (final s in _sets) if (s.ownerId == 'me' || s.visibility == 'public' || s.joined.contains('me') || _friends[s.ownerId] == (true, true)) _summary(s)];
  }

  @override
  Future<SetSummary> joinSet(String code) async {
    _seedSets();
    final s = _sets.where((s) => s.code == code.trim().toUpperCase()).firstOrNull;
    if (s == null) throw StateError('no such set');
    if (s.visibility == 'friends' && _friends[s.ownerId] != (true, true)) throw StateError('this set is friends-only');
    s.joined.add('me');
    return _summary(s);
  }

  _Set _set(String id) => _sets.firstWhere((s) => s.id == id);

  @override
  Future<List<Pair>> setNextPairs(String setId, {int n = 10}) async {
    final s = _set(setId);
    if (s.ownerId == 'me') throw StateError('you cannot rank your own set');
    final r = s.ratingsFor('me');
    final pool = [...s.items]..sort((a, b) => r[b.id]!.rd.compareTo(r[a.id]!.rd));
    final out = <Pair>[];
    final taken = <String>{};
    for (final a in pool) {
      if (out.length >= n || taken.contains(a.id)) continue;
      _Item? best;
      for (final b in pool) {
        if (b.id == a.id || taken.contains(b.id) || s.rated('me', a.id, b.id)) continue;
        if (best == null || (r[b.id]!.mu - r[a.id]!.mu).abs() < (r[best.id]!.mu - r[a.id]!.mu).abs()) best = b;
      }
      if (best == null) continue;
      taken.addAll([a.id, best.id]);
      out.add(Pair(aId: a.id, bId: best.id, aPath: a.path, bPath: best.path));
    }
    return out;
  }

  @override
  Future<void> setRecordDuel({required String setId, required String aId, required String bId, required String winnerId}) async {
    final s = _set(setId);
    if (s.done.contains('me')) throw StateError('you have already ranked this set');
    final a = s.items.firstWhere((i) => i.id == aId), b = s.items.firstWhere((i) => i.id == bId);
    if (s.rated('me', aId, bId)) throw StateError('pair already rated');
    s.duel('me', a, b, winnerId == aId ? a : b, s.ratingsFor('me'));
    if (s.duels.where((d) => d.rater == 'me').length >= s.required) s.done.add('me');
  }

  @override
  Future<List<SetBoardRow>> setBoard(String setId, {String? raterId}) async {
    final s = _set(setId);
    if (raterId != null && raterId != 'me' && s.ownerId != 'me') return const [];
    final r = raterId == null ? null : s.ratingsFor(raterId);
    final rows = [
      for (final i in s.items)
        (i, r == null ? i.rating : r[i.id]!, r == null ? i.duels : s.duels.where((d) => d.rater == raterId && (d.a == i.id || d.b == i.id)).length, r == null ? i.wins : s.duels.where((d) => d.rater == raterId && d.winner == i.id).length)
    ]..sort((x, y) {
        final c = y.$2.mu.compareTo(x.$2.mu);
        return c != 0 ? c : x.$1.ownerRank.compareTo(y.$1.ownerRank);
      });
    return [for (final (k, row) in rows.indexed) SetBoardRow(rank: k + 1, itemId: row.$1.id, storagePath: row.$1.path, ownerRank: row.$1.ownerRank, mu: row.$2.mu, duels: row.$3, wins: row.$4)];
  }

  @override
  Future<List<SetRater>> setRaters(String setId) async {
    final s = _set(setId);
    if (s.ownerId != 'me') return const [];
    final raters = {for (final d in s.duels) d.rater};
    return [for (final r in raters) SetRater(id: r, username: _profiles[r]?.username, duels: s.duels.where((d) => d.rater == r).length, done: s.done.contains(r), startedAt: DateTime.now())];
  }

  @override
  Future<FriendRow?> findProfile(String username) async {
    final u = username.trim().toLowerCase();
    final id = _profiles.entries.where((e) => e.value.username == u).firstOrNull?.key;
    if (id == null) return null;
    final f = _friends[id] ?? (false, false);
    return FriendRow(id: id, username: u, iFollow: f.$1, followsMe: f.$2, hasSet: _sets.any((s) => s.ownerId == id));
  }

  @override
  Future<List<FriendRow>> myFriends() async {
    _seedSets();
    return [
      for (final e in _friends.entries)
        if (e.value.$1 || e.value.$2) FriendRow(id: e.key, username: _profiles[e.key]?.username, iFollow: e.value.$1, followsMe: e.value.$2, hasSet: _sets.any((s) => s.ownerId == e.key)),
    ];
  }

  @override
  Future<void> follow(String userId, {bool unfollow = false}) async {
    final f = _friends[userId] ?? (false, false);
    _friends[userId] = (!unfollow, f.$2);
  }
}

class _Set {
  _Set({required this.id, required this.ownerId, required this.title, required this.visibility, required this.code});
  final String id;
  final String ownerId;
  final String title;
  String visibility;
  final String code;
  final items = <_Item>[];
  final duels = <({String rater, String a, String b, String winner})>[];
  final done = <String>{};
  final joined = <String>{};
  final _ratings = <String, Map<String, Rating>>{};

  int get required => (items.length * (items.length - 1) ~/ 2).clamp(0, 15);
  Map<String, Rating> ratingsFor(String rater) => _ratings.putIfAbsent(rater, () => {for (final i in items) i.id: const Rating(mu: 1500, rd: 350)});
  bool rated(String rater, String a, String b) => duels.any((d) => d.rater == rater && ((d.a == a && d.b == b) || (d.a == b && d.b == a)));

  void duel(String rater, _Item a, _Item b, _Item winner, Map<String, Rating> r) {
    if (rated(rater, a.id, b.id)) return;
    final (na, nb) = Glicko.updatePair(r[a.id]!, r[b.id]!, winner == a ? Outcome.win : Outcome.loss);
    r[a.id] = na;
    r[b.id] = nb;
    final (pa, pb) = Glicko.updatePair(a.rating, b.rating, winner == a ? Outcome.win : Outcome.loss);
    a
      ..rating = pa
      ..duels += 1
      ..wins += winner == a ? 1 : 0;
    b
      ..rating = pb
      ..duels += 1
      ..wins += winner == b ? 1 : 0;
    duels.add((rater: rater, a: a.id, b: b.id, winner: winner.id));
  }
}

class _Item {
  _Item({required this.id, required this.path, required this.ownerRank, this.takenAt});
  final String id;
  final String path;
  final int ownerRank;
  final DateTime? takenAt;
  Rating rating = const Rating(mu: 1500, rd: 350);
  int duels = 0;
  int wins = 0;
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
