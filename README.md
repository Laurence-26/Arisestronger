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
