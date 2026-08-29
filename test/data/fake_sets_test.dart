import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/data/arena/arena_models.dart';
import 'package:photorank/data/arena/fake_arena_api.dart';

void main() {
  test('sets: publish needs a username and 3–50 photos; replaces the old set', () async {
    final api = FakeArenaApi();
    await api.signIn();
    final items = [for (var i = 0; i < 5; i++) SetUploadItem(bytes: const [1], takenAt: DateTime(2026, 1, i + 1))];
    expect(() => api.publishSet(title: 'x', items: items), throwsStateError, reason: 'no username yet');
    await api.claimUsername('me_me');
    expect(() => api.publishSet(title: 'x', items: items.take(2).toList()), throwsStateError);
    final s = await api.publishSet(title: 'Summer', items: items);
    expect(s.mine, isTrue);
    expect(s.items, 5);
    expect(s.requiredDuels, 10);
    expect(s.linkCode, isNotNull);
    expect(s.visibility, 'friends');
    expect(s.raters, 2, reason: 'the fake has two bots rank a fresh set');
    final again = await api.publishSet(title: 'Autumn', items: items.take(3).toList(), visibility: 'public');
    expect((await api.visibleSets()).where((x) => x.mine).length, 1);
    expect(again.items, 3);
    expect(again.requiredDuels, 3);
    await api.setVisibility('link');
    expect((await api.visibleSets()).firstWhere((x) => x.mine).visibility, 'link');
    await api.unpublishSet();
    expect((await api.visibleSets()).any((x) => x.mine), isFalse);
  });

  test('sets: a friend\'s set is visible, ranked once, boards per rater plus pooled', () async {
    final api = FakeArenaApi();
    await api.signIn();
    final sets = await api.visibleSets();
    final friend = sets.firstWhere((s) => !s.mine);
    expect(friend.ownerUsername, 'player2');
    expect(friend.items, 8);
    expect(friend.requiredDuels, 15);
    expect(friend.myDone, isFalse);
    var duels = 0;
    while (true) {
      final pairs = await api.setNextPairs(friend.id, n: 10);
      if (pairs.isEmpty) break;
      for (final p in pairs) {
        expect(p.aId, isNot(p.bId));
        await api.setRecordDuel(setId: friend.id, aId: p.aId, bId: p.bId, winnerId: p.aId);
        duels++;
        if ((await api.visibleSets()).firstWhere((s) => s.id == friend.id).myDone) break;
      }
      if ((await api.visibleSets()).firstWhere((s) => s.id == friend.id).myDone) break;
    }
    expect(duels, 15);
    final after = (await api.visibleSets()).firstWhere((s) => s.id == friend.id);
    expect(after.myDone, isTrue);
    expect(after.myDuels, 15);
    expect(after.raters, 1);
    final first = (await api.setNextPairs(friend.id, n: 1));
    expect(() => api.setRecordDuel(setId: friend.id, aId: first.isEmpty ? 'set-bot1-1' : first.first.aId, bId: first.isEmpty ? 'set-bot1-2' : first.first.bId, winnerId: first.isEmpty ? 'set-bot1-1' : first.first.aId), throwsStateError, reason: 'one pass only');
    final mine = await api.setBoard(friend.id, raterId: 'me');
    final pooled = await api.setBoard(friend.id);
    expect(mine.length, 8);
    expect(pooled.length, 8);
    expect(mine.map((r) => r.rank).toList(), [1, 2, 3, 4, 5, 6, 7, 8]);
    expect(mine.every((r) => r.duels > 0), isTrue, reason: '15 duels over 8 photos touch every photo');
    expect(await api.setBoard(friend.id, raterId: 'bot3'), isEmpty, reason: 'only the owner reads other raters\' boards');
    expect(await api.setRaters(friend.id), isEmpty, reason: 'raters are the owner\'s view');
  });

  test('sets: link codes respect friends-only; friends are mutual follows', () async {
    final api = FakeArenaApi();
    await api.signIn();
    expect(() => api.joinSet('NOPE0000'), throwsStateError);
    final friends = await api.myFriends();
    expect(friends.where((f) => f.friends).map((f) => f.username), ['player2']);
    final found = await api.findProfile('Player4 ');
    expect(found, isNotNull);
    expect(found!.followsMe, isTrue);
    expect(found.iFollow, isFalse);
    await api.follow(found.id);
    expect((await api.findProfile('player4'))!.friends, isTrue);
    await api.follow(found.id, unfollow: true);
    expect((await api.findProfile('player4'))!.friends, isFalse);
    expect(await api.findProfile('nobody'), isNull);
  });
}
