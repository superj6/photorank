# PhotoRank — long-term roadmap

**End state in one sentence:** the taste layer over your camera roll. Sixty
seconds of play a day; in return the app runs your wallpaper, your widget,
your TV screensaver, your year-end recap, your shared trip albums — and knows
which of 20,000 photos you'd grab from a burning house.

Two loops, forever: **Rank** (input, the game) and **Enjoy** (output, what the
ranking earns you). Everything below strengthens one loop or the other.
Non-negotiables at every stage: nothing is ever deleted or hidden; photos never
leave the device unless the user explicitly shares; a session is ~90 seconds;
every interaction is a ranking signal.

---

> Status 2026-08-24: Phases 1–3 below are implemented (except the real-phone
> test and dealer tuning from real play), plus the in-play **beats** system
> that replaced calendar-only recaps as the engagement layer. Phase 4+ is open.

## Phase 1 — A loop you return to (v0.2)
Goal: you open it unprompted for a week straight.
- Real-phone test; debug overlay showing *why* each card was dealt.
- Dealer tuning from real play; anchor spacing for stars; hand size.
- Card physics: winner bounce, loser fly-away, spring-back; haptics per mode.
- Streak, XP/level, badges; session reveal with drama (hold back the new #1).
- Full-screen peek polish; landscape photos letterboxed instead of cropped.
- **Home-screen widget "Today's Duel"** — one tap from launcher into a card.
- Gentle daily reminder ("6 photos await a verdict"), opt-in.
- Scale: paginate `photoStates`, debounce ranking stream, pre-warm thumbnails.

Done when: D7 retention on yourself, ≥30 cards/day without trying.

## Phase 2 — Output you want to show (v0.3)
Goal: the ranking produces artefacts people screenshot and share.
- Share cards: *Top 9*, *#1 of the month/year*, *Photo Wrapped* stats.
- **Bracket mode**: Top 16 single-elimination, animated, shareable image.
- Export "Favorites" album; **sync Top-N to the system Favorites flag**
  (`MediaStore.IS_FAVORITE`) so Google Photos / Gallery show your ranking.
- Photo detail: full record, "who it beat", score history sparkline.

Done when: a share card gets sent to a friend unprompted.

## Phase 3 — A living library (v0.4)
Goal: the app stays relevant as new photos arrive every day.
- New-photo detection → "3 new shots — quick vibe check?" hand.
- Browse channels: *This Day*, *Rising*, *Deep Cuts*; auto-collections per
  month / year / trip / album / burst; slideshow & ambient mode; Chromecast.
- **Daily wallpaper from Top Shelf** (WallpaperManager) — the everyday hook.
- Perceptual hash near-duplicates feeding Best-of-Burst.
- On-device ML priors (aesthetic model) to shorten cold start; face/pet
  clustering → "best photo of each person", "best of each trip".

Done when: the widget/wallpaper make you notice photos you'd forgotten weekly.

## Phase 4 — More ways to play (v0.5)
Goal: variety keeps the game fresh after months.
- **Multiple axes**: Funny, Beautiful, Nostalgic, Share-worthy, custom.
  Axis picker in Play; per-axis Flow channels ("show me funny").
- New modes: Speed round (timed), Sudden-death ladder, Time-travel duels
  (2019 vs 2025), Theme decks (sunsets / dogs / one trip), Re-rank Top 10.
- Weekly recap notification with your top climber.

## Phase 5 — Social, offline first (v0.6)
Goal: it's fun with other people in the room; no accounts needed.
- **Pass-the-phone**: a friend plays a hand on your photos; agreement score;
  "photos you disagree on".
- **"Do you know me?"**: guess which of two the owner picked.
- Export/import of rating logs (QR / file) → couples merge rankings of a
  shared trip on one phone.

## Phase 6 — Cloud-optional, cross-platform (v1.0)
Goal: durable, multi-device, and shareable at distance — still photo-private.
- Ratings-only backup & sync (never photos); iOS parity + iOS widgets.
- Friend challenges ("rank my 16"); shared trip albums ranked by everyone.
- Public taste profile / Wrapped page as the viral surface.

## Phase 6b — Friends' sets (shipped 2026-08-28)
Turning the *library* ranking (not just the daily Arena entry) into something
friends can see and act on. Decisions taken: a set is ranked **once** per
friend; the owner sees **named** per-friend boards *and* a pooled aggregate;
visibility defaults to **friends only** (mutual follows), with friends + link
code and public as options; ranking a friend's set never touches your own
library ratings.
- Done: `supabase/migrations/0006_sets.sql` (sets, items, per-rater ratings,
  duels, passes, link access; `publish_set`, `visible_sets`, `set_next_pairs`,
  `set_record_duel`, `set_board`, `set_raters`, `find_profile`, `my_friends`),
  scenario test, Friends screen, publish sheet from the ranking, set ranking,
  boards with owner-order deltas.
- Next: a web view of a public set for people without the app; keep friends'
  passes when a re-publish only reorders; notifications ("@ana ranked your
  set"); a "most controversial photo" beat from the set boards.

## Phase 7 — Everyday layer (beyond 1.0)
- Android TV / Chromecast screensaver from Top Shelf; watch face.
- Auto yearbook; print / photobook export of Top 50.
- Lock-screen duel (notification with two images).
- Business model, if wanted: free core forever; Pro = extra axes, prints,
  cloud sync, TV app.

---

## Metrics to watch
- Cards per active day (health of Rank loop) — target 30+.
- % of library "settled" over time — should climb, then plateau.
- Browse sessions per day (health of Enjoy loop) — target ≥1.
- Shares per week; D1/D7/D30 retention once others are testing.

## Sequencing rule
Never add a new input surface (mode, axis) without a matching output surface
(channel, collection, share card). The game must always pay out.
