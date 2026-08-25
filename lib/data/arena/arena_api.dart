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

  Future<void> claimUsername(String username);
  Future<void> registerDeviceToken(String token, {required String platform});
  Future<void> follow(String userId, {bool unfollow = false});
  Future<void> block(String userId);
  Future<void> report(String entryId, String reason);

  /// A URL the image widget can load (signed, short-lived for Supabase).
  Future<String> imageUrl(String storagePath);
}
