import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'domain/pin_hasher.dart';
import 'settings_provider.dart';

/// Tests override this so time can be moved forward.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class LockState {
  final bool hasPin;
  final bool locked;
  final int pinLength;
  final int failures;
  final DateTime? retryAt;

  const LockState({
    required this.hasPin,
    required this.locked,
    this.pinLength = LockNotifier.minPinLength,
    this.failures = 0,
    this.retryAt,
  });

  LockState copyWith({
    bool? hasPin,
    bool? locked,
    int? pinLength,
    int? failures,
    DateTime? retryAt,
    bool clearRetryAt = false,
  }) => LockState(
    hasPin: hasPin ?? this.hasPin,
    locked: locked ?? this.locked,
    pinLength: pinLength ?? this.pinLength,
    failures: failures ?? this.failures,
    retryAt: clearRetryAt ? null : (retryAt ?? this.retryAt),
  );
}

class LockNotifier extends Notifier<LockState> {
  static const minPinLength = 4;
  static const maxPinLength = 6;
  static const _maxFreeAttempts = 5;

  static const _saltKey = 'pin_salt_v1';
  static const _hashKey = 'pin_hash_v1';
  static const _lengthKey = 'pin_length_v1';
  static const _failuresKey = 'pin_failures_v1';
  static const _retryKey = 'pin_retry_at_v1';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);
  DateTime get _now => ref.read(clockProvider)();

  @override
  LockState build() {
    final prefs = ref.read(sharedPrefsProvider);
    final hasPin =
        prefs.getString(_hashKey) != null && prefs.getString(_saltKey) != null;
    final retryMs = prefs.getInt(_retryKey);
    return LockState(
      hasPin: hasPin,
      locked: hasPin, // the app starts locked when a PIN exists
      pinLength: prefs.getInt(_lengthKey) ?? minPinLength,
      failures: prefs.getInt(_failuresKey) ?? 0,
      retryAt: retryMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(retryMs),
    );
  }

  /// How long the person must still wait before the next attempt.
  Duration get waitLeft {
    final retryAt = state.retryAt;
    if (retryAt == null) return Duration.zero;
    final left = retryAt.difference(_now);
    return left.isNegative ? Duration.zero : left;
  }

  static void _validate(String pin) {
    if (pin.length < minPinLength ||
        pin.length > maxPinLength ||
        !RegExp(r'^[0-9]+$').hasMatch(pin)) {
      throw ArgumentError('PIN must be $minPinLength to $maxPinLength digits');
    }
  }

  bool _matches(String pin) {
    final salt = _prefs.getString(_saltKey);
    final hash = _prefs.getString(_hashKey);
    if (salt == null || hash == null) return false;
    return PinHasher.verify(pin, salt, hash);
  }

  Future<void> _clearFailures() async {
    await _prefs.remove(_failuresKey);
    await _prefs.remove(_retryKey);
  }

  /// Checks a PIN, counting wrong attempts and applying the wait.
  Future<bool> _attempt(String pin) async {
    if (waitLeft > Duration.zero) return false;

    if (_matches(pin)) {
      await _clearFailures();
      state = state.copyWith(failures: 0, clearRetryAt: true);
      return true;
    }

    final failures = state.failures + 1;
    DateTime? retryAt;
    if (failures >= _maxFreeAttempts) {
      final exp = min(failures - _maxFreeAttempts, 5);
      final seconds = min(30 * (1 << exp), 900);
      retryAt = _now.add(Duration(seconds: seconds));
    }
    await _prefs.setInt(_failuresKey, failures);
    if (retryAt != null) {
      await _prefs.setInt(_retryKey, retryAt.millisecondsSinceEpoch);
    }
    state = state.copyWith(failures: failures, retryAt: retryAt);
    return false;
  }

  /// Returns true if the app is now unlocked.
  Future<bool> unlock(String pin) async {
    if (!state.hasPin) {
      state = state.copyWith(locked: false);
      return true;
    }
    final ok = await _attempt(pin);
    if (ok) state = state.copyWith(locked: false);
    return ok;
  }

  void lock() {
    if (state.hasPin && !state.locked) {
      state = state.copyWith(locked: true);
    }
  }

  /// Sets (or replaces) the PIN. Callers must check the old PIN first;
  /// use [changePin] for that.
  Future<void> setPin(String pin) async {
    _validate(pin);
    final salt = PinHasher.newSalt();
    await _prefs.setString(_saltKey, salt);
    await _prefs.setString(_hashKey, PinHasher.hash(pin, salt));
    await _prefs.setInt(_lengthKey, pin.length);
    await _clearFailures();
    state = LockState(hasPin: true, locked: false, pinLength: pin.length);
  }

  Future<bool> changePin(String current, String next) async {
    _validate(next);
    if (!await _attempt(current)) return false;
    await setPin(next);
    return true;
  }

  Future<bool> removePin(String current) async {
    if (!await _attempt(current)) return false;
    await _prefs.remove(_saltKey);
    await _prefs.remove(_hashKey);
    await _prefs.remove(_lengthKey);
    await _clearFailures();
    state = const LockState(hasPin: false, locked: false);
    return true;
  }
}

final lockProvider = NotifierProvider<LockNotifier, LockState>(
  LockNotifier.new,
);
