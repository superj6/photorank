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
  double get score => mu;

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
  double get score => mu;
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
  int? get percentile => rank == null || total <= 0 ? null : (100 - (rank! - 1) * 100 ~/ total).clamp(1, 100);
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
  const ArenaProfile({required this.id, this.username, this.displayName, this.recoverable = false});
  final String id;
  final String? username;
  final String? displayName;

  /// Linked to a recovery phrase: can be restored on another device.
  final bool recoverable;

  ArenaProfile copyWith({String? username, bool? recoverable}) =>
      ArenaProfile(id: id, username: username ?? this.username, displayName: displayName, recoverable: recoverable ?? this.recoverable);
}

/// Thrown when the stored session can no longer be refreshed. A recoverable
/// account is restored with its username + phrase; nothing is recreated.
class SessionExpired implements Exception {
  const SessionExpired({required this.recoverable});
  final bool recoverable;
  @override
  String toString() => recoverable ? 'Your sign-in expired. Restore your account with your username and recovery phrase.' : 'Your sign-in expired.';
}

/// Where the caller stands today: entered? rated the set? board unlocked?
class ArenaStatus {
  const ArenaStatus({required this.hasEntry, required this.duelsToday, required this.required, required this.unlocked, required this.others});
  final bool hasEntry;
  final int duelsToday;
  final int required;
  final bool unlocked;
  final int others;
  int get left => (required - duelsToday).clamp(0, required);
  static const none = ArenaStatus(hasEntry: false, duelsToday: 0, required: 0, unlocked: false, others: 0);
  static ArenaStatus fromJson(Map<String, dynamic> j) => ArenaStatus(
        hasEntry: j['has_entry'] as bool,
        duelsToday: j['duels_today'] as int,
        required: j['required'] as int,
        unlocked: j['unlocked'] as bool,
        others: j['others'] as int,
      );
}

/// A past day with a final board.
class DaySummary {
  const DaySummary({required this.day, required this.entries, required this.finalized, this.myFinalRank, this.myStoragePath});
  final DateTime day;
  final int entries;
  final bool finalized;
  final int? myFinalRank;
  final String? myStoragePath;
  static DaySummary fromJson(Map<String, dynamic> j) => DaySummary(
        day: DateTime.parse(j['day'] as String),
        entries: j['entries'] as int,
        finalized: j['finalized'] as bool,
        myFinalRank: j['my_final_rank'] as int?,
        myStoragePath: j['my_storage_path'] as String?,
      );
}

// ------------------------------------------------------------------ sets

/// A published Top-N set (yours or a friend's).
class SetSummary {
  const SetSummary({
    required this.id,
    required this.ownerId,
    this.ownerUsername,
    required this.title,
    required this.visibility,
    this.linkCode,
    required this.items,
    required this.updatedAt,
    required this.myDone,
    required this.myDuels,
    required this.raters,
    required this.mine,
  });
  final String id;
  final String ownerId;
  final String? ownerUsername;
  final String title;
  final String visibility; // friends | link | public
  final String? linkCode; // only on your own set
  final int items;
  final DateTime updatedAt;
  final bool myDone;
  final int myDuels;
  final int raters; // completed passes
  final bool mine;
  String get ownerName => ownerUsername != null ? '@$ownerUsername' : 'A friend';
  int get requiredDuels => (items * (items - 1) ~/ 2).clamp(0, 15);
  static SetSummary fromJson(Map<String, dynamic> j, {required String me}) => SetSummary(
        id: j['set_id'] as String,
        ownerId: j['owner_id'] as String,
        ownerUsername: j['owner_username'] as String?,
        title: j['title'] as String,
        visibility: j['visibility'] as String,
        linkCode: j['link_code'] as String?,
        items: j['items'] as int,
        updatedAt: DateTime.parse(j['updated_at'] as String),
        myDone: j['my_done'] as bool,
        myDuels: j['my_duels'] as int,
        raters: j['raters'] as int,
        mine: j['owner_id'] == me,
      );
}

/// One photo on a set board (a rater's own, or the pooled aggregate).
class SetBoardRow {
  const SetBoardRow({required this.rank, required this.itemId, required this.storagePath, required this.ownerRank, required this.mu, required this.duels, required this.wins});
  final int rank;
  final String itemId;
  final String storagePath;
  final int ownerRank;
  final double mu;
  final int duels;
  final int wins;
  double get score => mu;
  int get moved => ownerRank - rank; // + = rated higher than the owner ranks it
  static SetBoardRow fromJson(Map<String, dynamic> j) => SetBoardRow(
        rank: j['rank'] as int,
        itemId: j['item_id'] as String,
        storagePath: j['storage_path'] as String,
        ownerRank: j['owner_rank'] as int,
        mu: (j['mu'] as num).toDouble(),
        duels: j['duels'] as int,
        wins: j['wins'] as int,
      );
}

/// Someone who ranked (or started ranking) your set.
class SetRater {
  const SetRater({required this.id, this.username, required this.duels, required this.done, required this.startedAt});
  final String id;
  final String? username;
  final int duels;
  final bool done;
  final DateTime startedAt;
  String get name => username != null ? '@$username' : 'Anonymous';
  static SetRater fromJson(Map<String, dynamic> j) => SetRater(
        id: j['rater_id'] as String,
        username: j['username'] as String?,
        duels: j['duels'] as int,
        done: j['done'] as bool,
        startedAt: DateTime.parse(j['started_at'] as String),
      );
}

/// A player found by username, with the follow relation in both directions.
class FriendRow {
  const FriendRow({required this.id, this.username, required this.iFollow, required this.followsMe, this.hasSet = false});
  final String id;
  final String? username;
  final bool iFollow;
  final bool followsMe;
  final bool hasSet;
  bool get friends => iFollow && followsMe;
  String get name => username != null ? '@$username' : 'Anonymous';
  static FriendRow fromJson(Map<String, dynamic> j) => FriendRow(
        id: j['id'] as String,
        username: j['username'] as String?,
        iFollow: j['i_follow'] as bool,
        followsMe: j['follows_me'] as bool,
        hasSet: j['has_set'] as bool? ?? false,
      );
}

/// A photo to publish: already-prepared bytes plus its capture time.
class SetUploadItem {
  const SetUploadItem({required this.bytes, this.takenAt});
  final List<int> bytes;
  final DateTime? takenAt;
}
