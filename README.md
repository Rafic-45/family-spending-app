# 💸 Family Spend

A lightweight money tracker for **family use** — not a business tool. Everyone logs
their own money movements and they show up instantly in a **shared, live feed** that
the whole family sees.

Two kinds of entries:

- **Expense** — "I spent $45 on Groceries"
- **Transfer** — "I sent $100 to Karim (Allowance)"

```
💸  Rafic spent $45.00 on Groceries — Sep 18
🔄  Rafic sent $100.00 to Karim (Allowance) — Sep 18
```

Built with **Flutter** + **Supabase** (Postgres, Auth, Storage, Realtime).

---

## How it works

- **Sign in with just a name + password.** No email, no verification — it's just for
  family. Under the hood each name is mapped to a synthetic email
  (`karim@familyspend.local`) and accounts are auto-confirmed, so there's nothing to
  click in an inbox.
- **One family, shared ledger.** The first person **creates a family** and gets a short
  **invite code**. Everyone else **joins** with that code. All members see the same feed.
- **Live updates.** New entries stream in over Supabase Realtime — no refresh, no
  WhatsApp needed.
- **Optional receipt photos.** Attach a photo to any entry; it's stored in Supabase
  Storage and shown as a thumbnail in the feed.

Row Level Security makes sure a member only ever sees and writes entries for **their own
family**.

---

## Run it

Flutter's platform folders (`android/`, `ios/`, …) are **not committed** — they're
generated so they always match your Flutter version. First-time setup:

```bash
# 1. Get Flutter: https://docs.flutter.dev/get-started/install
flutter --version           # 3.4+ recommended

# 2. Generate the native platform folders (one time)
flutter create --platforms=android,ios .

# 3. Fetch packages and run on a connected device / emulator
flutter pub get
flutter run
```

That's it — the app is already wired to a live Supabase project (see `lib/config.dart`).

### Try it end to end (2 minutes)

1. Run the app on two devices/emulators (or run once, sign out, sign in as someone else).
2. On device A: sign up as **Rafic**, tap **Create**, name the family, note the **invite code**.
3. On device B: sign up as **Karim**, tap **Join**, enter the invite code.
4. Log an **expense** on one and a **transfer** to the other — watch it appear live in both feeds.

---

## Backend (Supabase)

A dedicated project has already been provisioned and configured:

- **Project:** `family-spend` (region `eu-central-1`)
- **URL:** `https://jqdgzeteqghqdozqxlmu.supabase.co`

The schema lives in [`supabase/migrations/`](supabase/migrations/):

| Table | What it holds |
| --- | --- |
| `families` | one household, with a unique `invite_code` |
| `profiles` | one row per user (name), linked to a family |
| `entries` | the shared ledger — `expense` or `transfer`, amount, date, note, optional `recipient_id` and `photo_url` |

Plus: `create_family` / `join_family` RPCs, an auto-profile + auto-confirm trigger on
new users, RLS policies scoping everything to the caller's family, a public `receipts`
storage bucket, and Realtime enabled on `entries`.

The publishable key in `lib/config.dart` is a **public** client key — it's safe to ship.
All access control is enforced by the database's RLS policies, not by keeping the key secret.

### Re-applying the schema elsewhere

To set up a fresh Supabase project, run the SQL files in `supabase/migrations/` in order
(via the SQL editor, the Supabase CLI, or `psql`), then drop the new project's URL +
publishable key into `lib/config.dart`.

---

## Notes & options

- **"Confirm email" fallback.** Accounts are auto-confirmed by a database trigger, and
  the app also signs in immediately after sign-up, so login just works. If you ever fork
  this to a project where sign-up still asks for confirmation, turn it off once in the
  dashboard: **Authentication → Sign In / Providers → Email → uncheck "Confirm email"**.
- **Receipt privacy.** The `receipts` bucket is **public** (unguessable UUID paths) so
  photos display with a simple URL. For stricter privacy, make the bucket private and
  switch `EntriesService.uploadReceipt` to return a signed URL
  (`createSignedUrl`) instead of `getPublicUrl`.
- **Currency symbol** is configurable in `lib/config.dart` (`currencySymbol`).

---

## Continuous integration

[`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml) runs on every push:
it regenerates the Android platform files, then `flutter analyze`, `flutter test`, and
`flutter build apk --release` — so the app is always verified to analyze, test, and build.

## Project layout

```
lib/
  main.dart              app entry + Supabase init
  config.dart            Supabase URL / anon key / currency
  theme.dart             light + dark Material 3 theme
  format.dart            amount + date formatting helpers
  models/                Entry, Family, Member
  services/              AuthService, FamilyService, EntriesService
  screens/               AuthGate, AuthScreen, OnboardingScreen, FeedScreen, AddEntryScreen
  widgets/               EntryTile
supabase/migrations/     database schema (SQL)
test/                    unit + widget tests
```
