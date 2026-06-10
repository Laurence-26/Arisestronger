# Daily Quest — Solo Leveling Fitness System

A Flutter + Supabase fitness app inspired by *Solo Leveling*. Complete your
daily quest, rank up from **E-Rank Hunter** to **Shadow Monarch**, and keep
getting stronger with daily motivation from scripture, timeless wisdom, and
the System itself.

## Features

- **Email/password accounts** with cloud sync (Supabase) across devices.
- **Full workout per rank** — every rank (E → Shadow Monarch) prescribes its
  own set of exercises with scaling targets (see `lib/data/rank_programs.dart`).
- **Onboarding sets your starting rank** from a self-reported fitness level:
  Beginner → E-Rank · Intermediate → C-Rank · Pro → B-Rank.
- **Custom exercises** — add your own workouts *on top* of the rank program, as
  **rep-based** (e.g. 30 push-ups) or **timed** (e.g. 60-second plank, with a
  built-in countdown timer).
- **Four-tab navigation** — Quest (today's workout) · Program (rank set + your
  exercises + rank roadmap) · Progress (streak, stats, 28-day history) · Profile.
- **Plan tomorrow** — after finishing today's quest, the System asks what
  *extra* workout you'll conquer tomorrow and locks it into the next day.
- **Rank / level progression** — 10 tiers on an *escalating* curve (7 days for
  the first rank-up, growing to ~25 for the top ranks; ~126 days E→Shadow
  Monarch). Quick early wins, a real long-term grind. Tune in
  `lib/models/level.dart` → `kRankDurations`.
- **First-miss grace** — the very first time you miss a day the System forgives
  you with a one-time **warning** (no progress lost). After that, misses trigger
  the Penalty Zone.
- **Penalty Zone** — once the grace is spent, missing a day deducts progress.
  The penalty *scales with rank* (`3 + 2 × rankIndex` days per missed day —
  gentle for beginners, harsh at the top) but is capped so one lapse drops you
  at most one rank.
- **Penalty-warning notification** — an evening reminder explicitly warns that
  an unfinished quest will be claimed by the Penalty Zone.
- **Daily motivation** — a rotating quote (Bible / wisdom / Solo Leveling)
  on the home screen *and* delivered as a real scheduled notification.
- **Real local notifications** — a daily reminder at your chosen time plus an
  evening "quest incomplete" nudge. Survives reboot.
- Running/GPS tracking from the old prototype has been **removed**.

## 1. Configure Supabase

1. Create a project at <https://supabase.com>.
2. Open **SQL Editor → New query**, paste all of [`supabase/schema.sql`](supabase/schema.sql),
   and **Run**. This creates the tables, Row-Level-Security policies, and a
   trigger that auto-creates a profile + starter exercises on sign-up.
3. Open **Project Settings → API** and copy your **Project URL** and **anon key**.
4. Paste them into [`lib/config/supabase_config.dart`](lib/config/supabase_config.dart),
   **or** pass them at build time (recommended — keeps keys out of source):

   ```bash
   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
               --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
   ```

5. (Optional) In **Authentication → Providers → Email**, turn *Confirm email*
   off for faster testing, or leave it on for production.

> Your project URL and publishable key are already filled into
> `lib/config/supabase_config.dart`, so the app runs as-is. Move them to
> `--dart-define` before publishing if you'd rather not commit them.

## 1b. Enable "Sign in with Google"

1. In **Google Cloud Console** → *APIs & Services → Credentials*, create an
   **OAuth 2.0 Client ID** (type: *Web application*). Under *Authorized redirect
   URIs* add your Supabase callback:
   `https://gtcztafphmtnyopofeze.supabase.co/auth/v1/callback`
2. In **Supabase → Authentication → Providers → Google**, paste that Client ID
   and Client Secret and enable the provider.
3. In **Supabase → Authentication → URL Configuration → Redirect URLs**, add:
   `com.sldq.dailyquest://login-callback/`
   (this is the app's deep-link scheme, already registered in
   `AndroidManifest.xml` and `ios/Runner/Info.plist`).

The "Continue with Google" button opens the system browser, then deep-links
back into the app and completes the session automatically.

## 2. Run

```bash
cd app
flutter pub get
flutter run
```

## 3. Build for release

**Android**
```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
Before publishing: set a real signing config in
`android/app/build.gradle.kts` (currently uses debug keys), and replace the
launcher icon. App id: `com.sldq.daily_quest`.

**iOS**
```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```
Open `ios/Runner.xcworkspace` in Xcode, set your Team & bundle id, and
archive. The notification foreground delegate is already wired in
`AppDelegate.swift`.

## Notifications

- Permission is requested from **Settings → Enable / test notifications**
  inside the app (Android 13+ and iOS require an explicit grant).
- The daily reminder time is set in the same screen and re-schedules
  automatically. Android boot receivers are declared so reminders persist
  across restarts.

## Store assets

Generated by `python tool/make_icon.py` into `assets/store/`:

| File | Use |
|---|---|
| `play_icon_512.png` | Google Play app icon (512×512) |
| `appstore_icon_1024.png` | App Store icon (1024×1024, no alpha) |
| `feature_graphic_1024x500.png` | Google Play feature graphic |

The launcher icon (`assets/icon/icon.png`) and splash logo (`assets/icon/splash.png`)
are also produced by that script — re-run it after editing the design.

**Screenshots:** store listings require real device screenshots, which need
the app running on an emulator/device against your live Supabase project
(`flutter run`, then capture 2–8 frames per platform). They can't be
pre-generated headlessly here.

## Project structure

```
lib/
  config/supabase_config.dart   Supabase URL + anon key
  data/quotes.dart              Bible / wisdom / Solo Leveling quotes
  models/                       Profile, Exercise, Level (ranks)
  services/                     SupabaseService, NotificationService
  state/app_state.dart          ChangeNotifier: progression + penalty logic
  widgets/                      RankCard, QuestTile, QuoteCard, overlays, sheets
  screens/                      Auth, Home, Settings, NotConfigured
supabase/schema.sql             Database schema + RLS + triggers
```
