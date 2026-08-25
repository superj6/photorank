import '../dealer/deck_theme.dart';
import '../rating/observation.dart';

export '../dealer/deck_theme.dart';

/// What kind of moment this is.
enum BeatKind {
  standings,
  mover,
  thenVsNow,
  headToHead,
  deepCut,
  burstCleared,
  settledPct,
  newTop,
  topTenOfficial,
  milestone,
  modeUnlocked,
  themedHand,
  welcomeBack,
  weekly,
  monthly,
  yearly,
}

/// Calendar recaps reuse the beat page system.
extension BeatKindX on BeatKind {
  bool get isCalendar => this == BeatKind.weekly || this == BeatKind.monthly || this == BeatKind.yearly;
}

enum BeatTier { minor, major }

/// An optional action the last page offers; the session controller knows how
/// to turn each into the next card(s).
sealed class BeatCta {
  const BeatCta();
  Map<String, dynamic> toJson();

  static BeatCta? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    return switch (j['type']) {
      'settleDuel' => SettleDuelCta(j['a'] as int, j['b'] as int),
      'vibeCheck' => VibeCheckCta(j['photoId'] as int),
      'tryMode' => TryModeCta(GameMode.values.byName(j['mode'] as String)),
      'themedDeck' => ThemedDeckCta(DeckTheme.values.byName(j['theme'] as String)),
      _ => null,
    };
  }
}

class SettleDuelCta extends BeatCta {
  const SettleDuelCta(this.a, this.b);
  final int a;
  final int b;
  @override
  Map<String, dynamic> toJson() => {'type': 'settleDuel', 'a': a, 'b': b};
}

class VibeCheckCta extends BeatCta {
  const VibeCheckCta(this.photoId);
  final int photoId;
  @override
  Map<String, dynamic> toJson() => {'type': 'vibeCheck', 'photoId': photoId};
}

class TryModeCta extends BeatCta {
  const TryModeCta(this.mode);
  final GameMode mode;
  @override
  Map<String, dynamic> toJson() => {'type': 'tryMode', 'mode': mode.name};
}

class ThemedDeckCta extends BeatCta {
  const ThemedDeckCta(this.theme);
  final DeckTheme theme;
  @override
  Map<String, dynamic> toJson() => {'type': 'themedDeck', 'theme': theme.name};
}

/// One full-screen page. Plain data; the UI decides how to render each.
sealed class BeatPage {
  const BeatPage();
  Map<String, dynamic> toJson();

  static BeatPage fromJson(Map<String, dynamic> j) {
    List<int> ints(String k) => (j[k] as List).cast<int>();
    return switch (j['type'] as String) {
      'standings' => StandingsPage(top: ints('top'), settled: j['settled'] as int, total: j['total'] as int),
      'mover' => MoverPage(
          photoId: j['photoId'] as int,
          scoreBefore: (j['scoreBefore'] as num).toDouble(),
          scoreAfter: (j['scoreAfter'] as num).toDouble(),
          rankBefore: j['rankBefore'] as int?,
          rankAfter: j['rankAfter'] as int?,
        ),
      'thenVsNow' => ThenVsNowPage(
          photoId: j['photoId'] as int,
          scoreThen: (j['scoreThen'] as num).toDouble(),
          scoreNow: (j['scoreNow'] as num).toDouble(),
          decisionsBetween: j['decisionsBetween'] as int,
          daysBetween: j['daysBetween'] as int,
        ),
      'headToHead' => HeadToHeadPage(a: j['a'] as int, b: j['b'] as int, aWins: j['aWins'] as int, bWins: j['bWins'] as int),
      'deepCut' => DeepCutPage(photoId: j['photoId'] as int, rank: j['rank'] as int, daysUnseen: j['daysUnseen'] as int),
      'burstCleared' => BurstClearedPage(winnerId: j['winnerId'] as int, siblingIds: ints('siblingIds')),
      'settled' => SettledPage(settled: j['settled'] as int, total: j['total'] as int, crossed: j['crossed'] as int),
      'newTop' => NewTopPage(photoId: j['photoId'] as int, previousId: j['previousId'] as int?),
      'topTen' => TopTenPage(ids: ints('ids')),
      'milestone' => MilestonePage(decisions: j['decisions'] as int, minutes: j['minutes'] as int, streak: j['streak'] as int),
      'modeUnlocked' => ModeUnlockedPage(GameMode.values.byName(j['mode'] as String)),
      'themedHand' => ThemedHandPage(DeckTheme.values.byName(j['theme'] as String), count: j['count'] as int),
      'welcomeBack' => WelcomeBackPage(
          daysAway: j['daysAway'] as int,
          newPhotos: j['newPhotos'] as int,
          topHeld: j['topHeld'] as bool,
          topId: j['topId'] as int?,
        ),
      'periodCover' => PeriodCoverPage(kind: BeatKind.values.byName(j['kind'] as String), label: j['label'] as String, start: DateTime.parse(j['start'] as String), end: DateTime.parse(j['end'] as String)),
      'numbers' => NumbersPage(decisions: j['decisions'] as int, sessions: j['sessions'] as int, minutes: j['minutes'] as int, streak: j['streak'] as int, newPhotos: j['newPhotos'] as int),
      'topNine' => TopNinePage(ids: ints('ids'), title: j['title'] as String),
      'bestOfPeriod' => BestOfPeriodPage(photoId: j['photoId'] as int, label: j['label'] as String),
      'bestOfMonths' => BestOfMonthsPage(entries: [for (final e in (j['entries'] as List)) ((e as Map)['month'] as int, e['photoId'] as int)]),
      'taste' => TastePage(portraitPct: j['portraitPct'] as int, favoriteMonth: j['favoriteMonth'] as int?, favoriteHour: j['favoriteHour'] as int?, photosTaken: j['photosTaken'] as int, photosRanked: j['photosRanked'] as int),
      'trend' => TrendPage(settledBefore: j['settledBefore'] as int, settledAfter: j['settledAfter'] as int, total: j['total'] as int),
      final t => throw ArgumentError('unknown page type $t'),
    };
  }
}

class StandingsPage extends BeatPage {
  const StandingsPage({required this.top, required this.settled, required this.total});
  final List<int> top; // up to 3, best first
  final int settled;
  final int total;
  @override
  Map<String, dynamic> toJson() => {'type': 'standings', 'top': top, 'settled': settled, 'total': total};
}

class MoverPage extends BeatPage {
  const MoverPage({required this.photoId, required this.scoreBefore, required this.scoreAfter, this.rankBefore, this.rankAfter});
  final int photoId;
  final double scoreBefore;
  final double scoreAfter;
  final int? rankBefore;
  final int? rankAfter;
  double get delta => scoreAfter - scoreBefore;
  @override
  Map<String, dynamic> toJson() => {
        'type': 'mover', 'photoId': photoId, 'scoreBefore': scoreBefore, 'scoreAfter': scoreAfter,
        'rankBefore': rankBefore, 'rankAfter': rankAfter,
      };
}

class ThenVsNowPage extends BeatPage {
  const ThenVsNowPage({required this.photoId, required this.scoreThen, required this.scoreNow, required this.decisionsBetween, required this.daysBetween});
  final int photoId;
  final double scoreThen;
  final double scoreNow;
  final int decisionsBetween;
  final int daysBetween;
  @override
  Map<String, dynamic> toJson() => {
        'type': 'thenVsNow', 'photoId': photoId, 'scoreThen': scoreThen, 'scoreNow': scoreNow,
        'decisionsBetween': decisionsBetween, 'daysBetween': daysBetween,
      };
}

class HeadToHeadPage extends BeatPage {
  const HeadToHeadPage({required this.a, required this.b, required this.aWins, required this.bWins});
  final int a;
  final int b;
  final int aWins;
  final int bWins;
  @override
  Map<String, dynamic> toJson() => {'type': 'headToHead', 'a': a, 'b': b, 'aWins': aWins, 'bWins': bWins};
}

class DeepCutPage extends BeatPage {
  const DeepCutPage({required this.photoId, required this.rank, required this.daysUnseen});
  final int photoId;
  final int rank;
  final int daysUnseen;
  @override
  Map<String, dynamic> toJson() => {'type': 'deepCut', 'photoId': photoId, 'rank': rank, 'daysUnseen': daysUnseen};
}

class BurstClearedPage extends BeatPage {
  const BurstClearedPage({required this.winnerId, required this.siblingIds});
  final int winnerId;
  final List<int> siblingIds;
  @override
  Map<String, dynamic> toJson() => {'type': 'burstCleared', 'winnerId': winnerId, 'siblingIds': siblingIds};
}

class SettledPage extends BeatPage {
  const SettledPage({required this.settled, required this.total, required this.crossed});
  final int settled;
  final int total;
  final int crossed; // 25, 50, 75, 100
  @override
  Map<String, dynamic> toJson() => {'type': 'settled', 'settled': settled, 'total': total, 'crossed': crossed};
}

class NewTopPage extends BeatPage {
  const NewTopPage({required this.photoId, this.previousId});
  final int photoId;
  final int? previousId;
  @override
  Map<String, dynamic> toJson() => {'type': 'newTop', 'photoId': photoId, 'previousId': previousId};
}

class TopTenPage extends BeatPage {
  const TopTenPage({required this.ids});
  final List<int> ids;
  @override
  Map<String, dynamic> toJson() => {'type': 'topTen', 'ids': ids};
}

class MilestonePage extends BeatPage {
  const MilestonePage({required this.decisions, required this.minutes, required this.streak});
  final int decisions;
  final int minutes;
  final int streak;
  @override
  Map<String, dynamic> toJson() => {'type': 'milestone', 'decisions': decisions, 'minutes': minutes, 'streak': streak};
}

class ModeUnlockedPage extends BeatPage {
  const ModeUnlockedPage(this.mode);
  final GameMode mode;
  @override
  Map<String, dynamic> toJson() => {'type': 'modeUnlocked', 'mode': mode.name};
}

class ThemedHandPage extends BeatPage {
  const ThemedHandPage(this.theme, {required this.count});
  final DeckTheme theme;
  final int count;
  @override
  Map<String, dynamic> toJson() => {'type': 'themedHand', 'theme': theme.name, 'count': count};
}

class WelcomeBackPage extends BeatPage {
  const WelcomeBackPage({required this.daysAway, required this.newPhotos, required this.topHeld, this.topId});
  final int daysAway;
  final int newPhotos;
  final bool topHeld;
  final int? topId;
  @override
  Map<String, dynamic> toJson() => {'type': 'welcomeBack', 'daysAway': daysAway, 'newPhotos': newPhotos, 'topHeld': topHeld, 'topId': topId};
}

class PeriodCoverPage extends BeatPage {
  const PeriodCoverPage({required this.kind, required this.label, required this.start, required this.end});
  final BeatKind kind;
  final String label;
  final DateTime start;
  final DateTime end;
  @override
  Map<String, dynamic> toJson() => {'type': 'periodCover', 'kind': kind.name, 'label': label, 'start': start.toIso8601String(), 'end': end.toIso8601String()};
}

class NumbersPage extends BeatPage {
  const NumbersPage({required this.decisions, required this.sessions, required this.minutes, required this.streak, required this.newPhotos});
  final int decisions;
  final int sessions;
  final int minutes;
  final int streak;
  final int newPhotos;
  @override
  Map<String, dynamic> toJson() => {'type': 'numbers', 'decisions': decisions, 'sessions': sessions, 'minutes': minutes, 'streak': streak, 'newPhotos': newPhotos};
}

class TopNinePage extends BeatPage {
  const TopNinePage({required this.ids, required this.title});
  final List<int> ids;
  final String title;
  @override
  Map<String, dynamic> toJson() => {'type': 'topNine', 'ids': ids, 'title': title};
}

class BestOfPeriodPage extends BeatPage {
  const BestOfPeriodPage({required this.photoId, required this.label});
  final int photoId;
  final String label;
  @override
  Map<String, dynamic> toJson() => {'type': 'bestOfPeriod', 'photoId': photoId, 'label': label};
}

class BestOfMonthsPage extends BeatPage {
  const BestOfMonthsPage({required this.entries});

  /// (month 1–12, photoId), in month order.
  final List<(int, int)> entries;
  @override
  Map<String, dynamic> toJson() => {'type': 'bestOfMonths', 'entries': [for (final e in entries) {'month': e.$1, 'photoId': e.$2}]};
}

class TastePage extends BeatPage {
  const TastePage({required this.portraitPct, this.favoriteMonth, this.favoriteHour, required this.photosTaken, required this.photosRanked});
  final int portraitPct;
  final int? favoriteMonth;
  final int? favoriteHour;
  final int photosTaken;
  final int photosRanked;
  @override
  Map<String, dynamic> toJson() => {'type': 'taste', 'portraitPct': portraitPct, 'favoriteMonth': favoriteMonth, 'favoriteHour': favoriteHour, 'photosTaken': photosTaken, 'photosRanked': photosRanked};
}

class TrendPage extends BeatPage {
  const TrendPage({required this.settledBefore, required this.settledAfter, required this.total});
  final int settledBefore;
  final int settledAfter;
  final int total;
  @override
  Map<String, dynamic> toJson() => {'type': 'trend', 'settledBefore': settledBefore, 'settledAfter': settledAfter, 'total': total};
}

/// A generated moment: 1–3 pages, an optional CTA, shareable or not.
class Beat {
  const Beat({
    required this.kind,
    required this.tier,
    required this.pages,
    required this.decisionCount,
    this.cta,
    this.shareable = false,
    this.id,
  });

  final int? id;
  final BeatKind kind;
  final BeatTier tier;
  final List<BeatPage> pages;
  final int decisionCount;
  final BeatCta? cta;
  final bool shareable;

  Beat withId(int id) => Beat(
      id: id, kind: kind, tier: tier, pages: pages, decisionCount: decisionCount, cta: cta, shareable: shareable);

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'tier': tier.name,
        'pages': pages.map((p) => p.toJson()).toList(),
        'cta': cta?.toJson(),
        'shareable': shareable,
      };

  static Beat fromJson(Map<String, dynamic> j, {required int decisionCount, int? id}) => Beat(
        id: id,
        kind: BeatKind.values.byName(j['kind'] as String),
        tier: BeatTier.values.byName(j['tier'] as String),
        pages: (j['pages'] as List).map((p) => BeatPage.fromJson((p as Map).cast<String, dynamic>())).toList(),
        cta: BeatCta.fromJson((j['cta'] as Map?)?.cast<String, dynamic>()),
        shareable: j['shareable'] as bool? ?? false,
        decisionCount: decisionCount,
      );
}
