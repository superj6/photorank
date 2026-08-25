/// Plain models mirroring the SQL functions' return rows.
class BoardRow {
  const BoardRow({
    required this.rank,
    required this.entryId,
    required this.userId,
    this.username,
    this.displayName,
    required this.storagePath,
    required this.mu,
    required this.rd,
    required this.duels,
    required this.wins,
    required this.settled,
    required this.mine,
    required this.total,
  });

  final int rank;
  final String entryId;
  final String userId;
  final String? username;
  final String? displayName;
  final String storagePath;
  final double mu;
  final double rd;
  final int duels;
  final int wins;
  final bool settled;
  final bool mine;
  final int total;

  String get name => username != null ? '@$username' : (displayName ?? 'Anonymous');
  double get score => ((mu - 1000) / 1000 * 100).clamp(0, 100).toDouble();

  static BoardRow fromJson(Map<String, dynamic> j) => BoardRow(
        rank: j['rank'] as int,
        entryId: j['entry_id'] as String,
        userId: j['user_id'] as String,
        username: j['username'] as String?,
        displayName: j['display_name'] as String?,
        storagePath: j['storage_path'] as String,
        mu: (j['mu'] as num).toDouble(),
        rd: (j['rd'] as num).toDouble(),
        duels: j['duels'] as int,
        wins: j['wins'] as int,
        settled: j['settled'] as bool,
        mine: j['mine'] as bool,
        total: j['total'] as int,
      );
}

class MyEntry {
  const MyEntry({required this.rank, required this.entryId, required this.storagePath, required this.mu, required this.duels, required this.wins, required this.settled, required this.total});
  final int rank;
  final String entryId;
  final String storagePath;
  final double mu;
  final int duels;
  final int wins;
  final bool settled;
  final int total;
  double get score => ((mu - 1000) / 1000 * 100).clamp(0, 100).toDouble();
  int get percentile => total <= 1 ? 100 : (100 - (rank - 1) * 100 ~/ total).clamp(1, 100);

  static MyEntry fromJson(Map<String, dynamic> j) => MyEntry(
        rank: j['rank'] as int,
        entryId: j['entry_id'] as String,
        storagePath: j['storage_path'] as String,
        mu: (j['mu'] as num).toDouble(),
        duels: j['duels'] as int,
        wins: j['wins'] as int,
        settled: j['settled'] as bool,
        total: j['total'] as int,
      );
}

class Pair {
  const Pair({required this.aId, required this.bId, required this.aPath, required this.bPath});
  final String aId;
  final String bId;
  final String aPath;
  final String bPath;
  static Pair fromJson(Map<String, dynamic> j) =>
      Pair(aId: j['a_id'] as String, bId: j['b_id'] as String, aPath: j['a_path'] as String, bPath: j['b_path'] as String);
}

class HistoryRow {
  const HistoryRow({required this.day, this.roomId, required this.entryId, required this.storagePath, this.finalRank, this.liveRank, required this.total, required this.duels, required this.wins, required this.status});
  final DateTime day;
  final String? roomId;
  final String entryId;
  final String storagePath;
  final int? finalRank;
  final int? liveRank;
  final int total;
  final int duels;
  final int wins;
  final String status;
  int? get rank => finalRank ?? liveRank;
  static HistoryRow fromJson(Map<String, dynamic> j) => HistoryRow(
        day: DateTime.parse(j['day'] as String),
        roomId: j['room_id'] as String?,
        entryId: j['entry_id'] as String,
        storagePath: j['storage_path'] as String,
        finalRank: j['final_rank'] as int?,
        liveRank: j['live_rank'] as int?,
        total: j['total'] as int,
        duels: j['duels'] as int,
        wins: j['wins'] as int,
        status: j['status'] as String,
      );
}

class Room {
  const Room({required this.id, required this.code, required this.name, required this.ownerId, this.members = 1});
  final String id;
  final String code;
  final String name;
  final String ownerId;
  final int members;
  static Room fromJson(Map<String, dynamic> j) => Room(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        ownerId: j['owner_id'] as String,
        members: j['members'] as int? ?? 1,
      );
}

class ArenaProfile {
  const ArenaProfile({required this.id, this.username, this.displayName});
  final String id;
  final String? username;
  final String? displayName;
}
