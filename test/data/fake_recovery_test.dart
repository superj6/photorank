import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/data/arena/fake_arena_api.dart';

void main() {
  test('a username cannot exist without a recovery phrase; restore brings the account back', () async {
    final api = FakeArenaApi();
    await api.signIn();
    expect(() => api.claimUsername('sam'), throwsStateError, reason: 'no phrase, no username');
    await api.claimUsername('sam', recoveryPhrase: 'apple-bee-cat-dog-egg');
    expect(api.me!.username, 'sam');
    expect(api.me!.recoverable, isTrue);
    await api.claimUsername('samantha'); // rename keeps the phrase
    expect(api.me!.username, 'samantha');
    expect(() => api.restore('samantha', 'wrong-words-here-now-ok'), throwsStateError);
    final back = await api.restore('samantha', 'apple-bee-cat-dog-egg');
    expect(back.username, 'samantha');
    expect(() => api.claimUsername('player2', recoveryPhrase: 'x-x-x-x-x-x-x'), throwsStateError, reason: 'taken by a bot');
    await api.setRecoveryPhrase('new-phrase-for-this-one');
    expect(() => api.restore('samantha', 'apple-bee-cat-dog-egg'), throwsStateError, reason: 'old phrase stops working');
    expect((await api.restore('samantha', 'new-phrase-for-this-one')).recoverable, isTrue);
  });
}
