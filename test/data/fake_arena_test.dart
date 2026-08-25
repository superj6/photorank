import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/data/arena/fake_arena_api.dart';

void main() {
  test('arena rules: one entry, own photo never paired, ratings move, board ranks', () async {
    final api = FakeArenaApi();
    await api.signIn();
    expect(() => api.submit(Uint8List(0), takenAt: DateTime.now().subtract(const Duration(days: 3))), throwsStateError);
    await api.submit(Uint8List(0), takenAt: DateTime.now());
    expect(() => api.submit(Uint8List(0), takenAt: DateTime.now()), throwsStateError);
    var st = await api.status();
    expect(st.hasEntry, isTrue);
    expect(st.required, 10);
    expect(st.unlocked, isFalse);
    expect(await api.leaderboard(), isEmpty, reason: 'board hidden until the set is rated');
    expect(await api.myEntry(), isNull);
    final pairs = await api.nextPairs(n: 10);
    expect(pairs.length, 6, reason: '12 bots pair into 6 disjoint duels per call');
    expect(pairs.every((p) => p.aId != 'me-g' && p.bId != 'me-g'), isTrue);
    for (final p in pairs) {
      await api.recordDuel(aId: p.aId, bId: p.bId, winnerId: p.aId);
    }
    expect(() => api.recordDuel(aId: pairs.first.aId, bId: pairs.first.bId, winnerId: pairs.first.aId), throwsStateError);
    for (final p in await api.nextPairs(n: 4)) {
      await api.recordDuel(aId: p.aId, bId: p.bId, winnerId: p.bId);
    }
    st = await api.status();
    expect(st.duelsToday, 10);
    expect(st.unlocked, isTrue);
    final after = await api.leaderboard();
    expect(after.length, 13);
    expect(after.first.rank, 1);
    expect((await api.myEntry())!.settled, isFalse, reason: 'own entry has no duels yet');
    expect((await api.days()).length, 7);
    expect((await api.leaderboard(day: DateTime.now().toUtc().subtract(const Duration(days: 1)))).length, 12);
    expect((await api.myHistory()).length, greaterThanOrEqualTo(6));
    final room = await api.createRoom('Family');
    expect((await api.leaderboard(roomId: room.id)).length, 4);
  });
}
