import 'dart:typed_data';

import 'arena_models.dart';

/// Everything the Arena UI needs from the backend. One real implementation
/// (Supabase) and one in-memory fake for tests and offline development.
abstract class ArenaApi {
  Future<ArenaProfile> signIn();
  ArenaProfile? get me;

  /// Uploads a prepared image and registers today's entry. [takenAt] is the
  /// photo's capture time; the server rejects photos not from today.
  Future<void> submit(Uint8List jpegBytes, {required DateTime takenAt, String? roomId});
  Future<ArenaStatus> status({String? roomId});
  Future<MyEntry?> myEntry({DateTime? day, String? roomId});
  Future<void> deleteEntry(String entryId);

  Future<List<Pair>> nextPairs({String? roomId, int n = 10});
  Future<void> recordDuel({required String aId, required String bId, required String winnerId});

  Future<List<BoardRow>> leaderboard({DateTime? day, String? roomId, String scope = 'global', int limit = 100, int offset = 0});
  Future<List<HistoryRow>> myHistory();
  Future<List<DaySummary>> days({String? roomId});

  Future<List<Room>> myRooms();
  Future<Room> createRoom(String name);
  Future<Room> joinRoom(String code);

  /// Claims [username] and, in the same step, links the account to a
  /// recovery phrase — a username is never allowed to exist without one.
  /// Pass [recoveryPhrase] the first time; later renames keep the phrase.
  Future<void> claimUsername(String username, {String? recoveryPhrase});

  /// Signs this device into an existing account by username + phrase,
  /// replacing whatever anonymous account it had.
  Future<ArenaProfile> restore(String username, String recoveryPhrase);

  /// Replaces the recovery phrase of a recoverable account.
  Future<void> setRecoveryPhrase(String recoveryPhrase);

  /// Permanently deletes the arena account: uploaded photos, entries, sets,
  /// duels, follows — everything server-side. Local ratings are untouched.
  Future<void> deleteAccount();

  /// null when the name is free, otherwise the profile holding it.
  Future<FriendRow?> findProfile(String username);
  Future<void> registerDeviceToken(String token, {required String platform});
  Future<void> follow(String userId, {bool unfollow = false});
  Future<void> block(String userId);
  Future<void> report(String entryId, String reason);

  /// A URL the image widget can load (signed, short-lived for Supabase).
  Future<String> imageUrl(String storagePath);

  // --- Published sets (your Top N, ranked by friends) ---

  /// Uploads every item (already downsized and stripped) and replaces your set.
  Future<SetSummary> publishSet({required String title, required List<SetUploadItem> items, String visibility = 'friends'});
  Future<void> unpublishSet();
  Future<void> setVisibility(String visibility);

  /// Your set first, then every friend's set you may see.
  Future<List<SetSummary>> visibleSets();
  Future<SetSummary> joinSet(String code);
  Future<List<Pair>> setNextPairs(String setId, {int n = 10});
  Future<void> setRecordDuel({required String setId, required String aId, required String bId, required String winnerId});

  /// [raterId] null = the pooled aggregate; otherwise that rater's own board
  /// (yours, or any rater's if you own the set).
  Future<List<SetBoardRow>> setBoard(String setId, {String? raterId});
  Future<List<SetRater>> setRaters(String setId);

  // --- Friends (mutual follows) ---
  Future<List<FriendRow>> myFriends();
}
