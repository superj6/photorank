import 'package:flutter_test/flutter_test.dart';
import 'package:photorank/core/rating/anchors.dart';
import 'package:photorank/core/rating/glicko.dart';

void main() {
  group('Glicko', () {
    test('equal ratings expect 0.5', () {
      expect(Glicko.expected(Rating.initial, Rating.initial), closeTo(0.5, 1e-9));
    });

    test('win raises mu and lowers rd; loss lowers mu', () {
      final win = Glicko.updateOne(Rating.initial, Rating.initial, Outcome.win);
      final loss = Glicko.updateOne(Rating.initial, Rating.initial, Outcome.loss);
      expect(win.mu, greaterThan(Rating.initialMu));
      expect(win.rd, lessThan(Rating.initialRd));
      expect(loss.mu, lessThan(Rating.initialMu));
      expect(win.mu - Rating.initialMu, closeTo(Rating.initialMu - loss.mu, 1e-9));
    });

    test('pair update is symmetric from pre-update values', () {
      final (a, b) = Glicko.updatePair(Rating.initial, Rating.initial, Outcome.win);
      expect(a.mu, greaterThan(b.mu));
      expect(a.mu - Rating.initialMu, closeTo(Rating.initialMu - b.mu, 1e-9));
    });

    test('lower weight moves less', () {
      final full = Glicko.updateOne(Rating.initial, Anchors.at(Anchors.vibe), Outcome.win);
      final light =
          Glicko.updateOne(Rating.initial, Anchors.at(Anchors.vibe), Outcome.win, weight: 0.3);
      expect(light.mu - Rating.initialMu, lessThan(full.mu - Rating.initialMu));
      expect(light.rd, greaterThan(full.rd));
    });

    test('rd never leaves [minRd, initialRd]', () {
      var r = Rating.initial;
      for (var i = 0; i < 500; i++) {
        r = Glicko.updateOne(r, Anchors.star(5), Outcome.win);
      }
      expect(r.rd, greaterThanOrEqualTo(Rating.minRd));
      expect(r.rd, lessThanOrEqualTo(Rating.initialRd));
    });

    test('score is a win chance vs an average photo and never saturates', () {
      expect(Rating.initial.score, closeTo(50, 1e-9));
      expect(const Rating(mu: 2000, rd: 30).score, closeTo(94.7, 0.1));
      expect(const Rating(mu: 500, rd: 350).score, greaterThan(0));
      expect(const Rating(mu: 2500, rd: 30).score, lessThan(100));
      // Strictly monotonic: two photos never tie in the display at the top.
      expect(const Rating(mu: 2280, rd: 30).score, greaterThan(const Rating(mu: 2270, rd: 30).score));
      expect(Rating.initial.confidence, 0);
      expect(const Rating(mu: 1500, rd: 30).confidence, 1);
    });
  });
}
