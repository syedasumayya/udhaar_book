# Udhaar Book

[![CI](https://github.com/syedasumayya/udhaar_book/actions/workflows/dart.yml/badge.svg)](https://github.com/syedasumayya/udhaar_book/actions/workflows/dart.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Udhaar Book, a Flutter app for tracking money you lend or borrow. It handles people, loans, partial repayments, overdue tracking, PIN lock, backup/restore and WhatsApp summaries. It works offline, has automated tests and CI, and is deployed to the web with GitHub Pages

**Live demo:** https://syedasumayya.github.io/udhaar_book/

## Features

- **People and loans**: record money you gave or took, with a date, a due date
  and a note
- **Repayments**: partial payments, payment history, "Mark paid", and
  "Settle all" to close every open loan with one person
- **Dashboard**: what people owe you, what you owe, your net position, overdue
  loans, loans due in the next 7 days, and your biggest balances
- **Share a summary**: build a short statement of what is owed with one person,
  then copy it or send it through WhatsApp
- **Search and filters** on the People list (all, owes you, you owe, settled)
- **Edit** people and loans, with checks that stop you from breaking balances
  (for example, lowering a loan below what is already paid)
- **PIN lock**: 4 to 6 digits, stored as a salted hash, with a timed lockout
  after repeated wrong attempts
- **Backup and restore**: copy your whole ledger as text and restore it later;
  a backup is fully validated before anything is replaced
- **CSV export** for Excel or Google Sheets
- **Light, dark and system themes**
- **Works offline**, and corrupted stored data is set aside instead of
  crashing the app

## Try it

| Where | How |
|---|---|
| **Web** | Open the live demo. On a phone, choose *Add to Home screen* in your browser menu to install it like an app. |
| **Android** | Open the **Actions** tab, run **Build Android APK**, download the `udhaar-book-apk` artifact, unzip it and install `app-release.apk`. |
| **From source** | See below. |

## Run from source

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(developed on Flutter 3.44).

```bash
git clone https://github.com/syedasumayya/udhaar_book.git
cd udhaar_book
flutter pub get
flutter run -d chrome
```

## Test

```bash
flutter analyze
flutter test
```

GitHub Actions runs both on every push and pull request, and deploys the web
app from `main`.

## How it works

- Money is stored as whole **paisa** (integers), never as decimals, so there
  are no rounding errors.
- A loan's remaining balance is **calculated** from the loan and its
  repayments. It is never stored, so it cannot go out of sync.
- Storage sits behind an `AppRepository` interface. Today it uses
  `shared_preferences`, and another implementation can replace it without
  touching any screen.
- State management uses [Riverpod](https://riverpod.dev).
- Rules such as "a payment cannot exceed what is left" are enforced in the
  state layer, not only in the forms.

## Project structure

```
lib/
  core/        theme, money and date helpers
  data/        models and storage (repository interface + implementation)
  domain/      balance math, backup, CSV, PIN hashing, summary text
  features/    dashboard, people, loans, settings, lock screen
  providers.dart, lock_provider.dart, settings_provider.dart
test/          unit, state and widget tests
.github/       CI, web deploy and Android build workflows
```

## License

MIT. See [LICENSE](LICENSE).
