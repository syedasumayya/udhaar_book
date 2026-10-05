# Udhaar Book

A Flutter app to track money you have lent or borrowed: people, loans,
repayments, balances and overdue reminders. Works offline.

## Run
    flutter pub get
    flutter run -d chrome

## Test
    flutter test

## Notes
- Money is stored as integer paisa to avoid rounding errors.
- Balances are calculated from loans and repayments, never stored.


