# Google Play listing

**App name:** PhotoRank
**Short description (80 chars max):**
A tiny game that sorts your camera roll. Swipe, duel, rate — find your keepers.

**Full description:**
Thousands of photos, and no idea which ones you actually love? PhotoRank turns
sorting them into a game you can play in a minute a day.

Open the app and you're dealt a hand: which of these two? Feeling this one or
not? Best shot of this burst? Rate it out of five. Every swipe is a decision,
and every decision sharpens a ranking of your whole library — so over time your
favourites float to the top, all on their own.

• Six ways to decide: Duel, Vibe check, Rate, Best of burst, Sort three,
  Challenger — unlocking as you play
• Moments that keep it fresh: your Top 3, a new #1, a climber, a themed hand
• Weekly, monthly and yearly recaps of your photos
• Browse your ranking as a flow, auto-collections, a slideshow for the sofa
• A Top-16 bracket, share cards, and "pass the phone" to see if friends agree
• A home-screen widget: today's duel, one tap from the launcher
• Rank along more than one axis — Love, Funny, Beautiful, your own

Private by design: ranking is fully on-device — PhotoRank reads the photos
already on your phone and stores only ratings, locally. No ads, and nothing is
ever deleted, moved or hidden; the bottom of the ranking is just the bottom.
The online parts are strictly opt-in: enter one photo a day in the global
Arena, or publish your Top 10 for friends to rank — only the photos you
choose are uploaded (downsized, location and camera data removed), and you
can delete them or the whole account any time.

**Category:** Photography
**Tags:** photos, gallery, organize, ranking, game

**Privacy policy URL:** https://photorank.jgon.net/privacy.html

## Data safety form (answers)
The Play build ships with Arena pointed at https://photorank.jgon.net:
- Collected: **Photos** (user-initiated, optional — the one daily entry),
  **User IDs** (anonymous account), **App interactions** (duel choices).
  Purpose: app functionality. Not shared with third parties.
- Encrypted in transit: **Yes** (HTTPS). Users can request deletion: **Yes**
  (in-app: Settings → Delete arena account).
- Account deletion URL (required field): https://photorank.jgon.net/delete-account.html
- Photos and videos on the device are otherwise accessed on-device only.

## User-generated content (Play policy)
Arena shows photos uploaded by users. The app has in-app **report** and
**block**, reported content is auto-hidden after 3 reports pending review,
and the consent sheet states the rules and the 13+ requirement.

## Content rating questionnaire
- No violence, sexual content, profanity, or gambling.
- **User-generated content: YES** — Arena entries and published friend sets
  are user photos shown to others, with in-app report + block and moderation
  (answer the UGC questions accordingly). Expected rating: **Everyone /
  PEGI 3**, possibly Teen depending on the UGC branch.

## App access
- No login required. All features are available without credentials.

## Photos permission declaration
- READ_MEDIA_IMAGES is core functionality: the app's purpose is organising /
  ranking the user's photo library on-device. Declare "photo and video
  management" as the core use case when the console asks.

## Assets
- Icon: `assets/icon/icon.png` (512×512 export for Play)
- Feature graphic: `docs/store/feature-graphic.png` (1024×500)
- Phone screenshots: take 4–8 on a real device (1080×2400) — Play requires
  at least 2. The emulator strips in `docs/screenshots/` use placeholder
  images; real photos look far better in the listing.

## Release checklist
1. `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`
2. Play Console → Testing → Internal testing → create release, upload the .aab
3. Add testers by email or share the opt-in link
4. Closed testing with ≥12 testers for 14 days (required for new personal accounts)
5. Production
