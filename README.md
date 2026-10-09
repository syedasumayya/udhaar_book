# Udhaar Book

[![CI](https://github.com/syedasumayya/udhaar_book/actions/workflows/dart.yml/badge.svg)](https://github.com/syedasumayya/udhaar_book/actions/workflows/dart.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A private ledger for money you lend or borrow. Track people, loans and
repayments, see who owes whom, and spot what is overdue. Built with Flutter.
Everything is stored on your own device.

## Features

- **People and loans**: record money you gave or took, with a date, a due date
  and a note
- **Repayments**: partial payments, payment history, "Mark paid", and
  "Settle all" for everything you owe or are owed by one person
- **Dashboard**: what people owe you, what you owe, your net position, overdue
  loans, loans due in the next 7 days, and your biggest balances
- **Search and filters** on the People list (all, owes you, you owe, settled)
- **Edit** people and loans, with checks that stop you from breaking the
  balances (for example, lowering a loan below what is already paid)
- **PIN lock**: 4 to 6 digits, stored as a salted hash, with a timed lockout
  after repeated wrong attempts
- **Backup and restore**: copy your whole ledger as text and restore it later
  (the backup is validated before anything is replaced)
- **CSV export** for Excel or Google Sheets
- **Light, dark and system themes**
- **Works offline**: no account and no server

## How it works

- Money is stored as whole **paisa** (integers), never as decimals, so there
  are no rounding errors.
- A loan's remaining balance is **calculated** from the loan and its
  repayments. It is never stored, so it cannot go out of sync.
- Storage sits behind an `AppRepository` interface. Today it uses
  `shared_preferences`; a SQLite version can replace it without changing any
  screen.
- State management uses [Riverpod](https://riverpod.dev).

## Run it

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

GitHub Actions runs both on every push and pull request.

## Project structure

```
lib/
  core/        theme, money and date helpers
  data/        models and storage (repository interface + implementation)
  domain/      balance math, backup, CSV export, PIN hashing
  features/    dashboard, people, loans, settings, lock screen
  providers.dart, lock_provider.dart, settings_provider.dart
test/          unit, state and widget tests
```

## Limits

- Data lives in this browser or device only. Use **Settings > Copy backup** to
  move it between devices.
- The PIN lock is a privacy lock, not encryption. If you forget the PIN, the
  only way back in is clearing the app's data, so keep a backup.
- Reminders and notifications are not built yet.

## Roadmap

- [ ] Due-date reminders (notifications)
- [ ] SQLite storage
- [ ] App icon
- [ ] Share a balance summary with a contact

## License

MIT. See [LICENSE](LICENSE).
