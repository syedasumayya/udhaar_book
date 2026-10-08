import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lock_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _entry = '';
  String? _message;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refreshes the "try again in Ns" countdown.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _press(String digit) async {
    final notifier = ref.read(lockProvider.notifier);
    final pinLength = ref.read(lockProvider).pinLength;
    if (notifier.waitLeft > Duration.zero) return;
    if (_entry.length >= pinLength) return;

    setState(() {
      _entry += digit;
      _message = null;
    });

    if (_entry.length == pinLength) {
      final ok = await notifier.unlock(_entry);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _entry = '';
          _message = 'Wrong PIN';
        });
      }
    }
  }

  void _backspace() {
    if (_entry.isEmpty) return;
    setState(() {
      _entry = _entry.substring(0, _entry.length - 1);
      _message = null;
    });
  }

  Widget _keypad(bool disabled) {
    Widget digit(String d) => _Key(
      onTap: disabled ? null : () => _press(d),
      child: Text(d, style: const TextStyle(fontSize: 26)),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          _KeyRow([for (final d in row) digit(d)]),
        _KeyRow([
          const SizedBox(width: 72, height: 72),
          digit('0'),
          _Key(
            onTap: disabled ? null : _backspace,
            child: const Icon(Icons.backspace_outlined),
          ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(lockProvider);
    final wait = ref.read(lockProvider.notifier).waitLeft;
    final waiting = wait > Duration.zero;
    final seconds = (wait.inMilliseconds / 1000).ceil();
    final scheme = Theme.of(context).colorScheme;

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final ch = event.character;
        if (ch != null && RegExp(r'^[0-9]$').hasMatch(ch)) {
          _press(ch);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          _backspace();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 48, color: scheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Udhaar Book is locked',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < lock.pinLength; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < _entry.length
                                ? scheme.primary
                                : Colors.transparent,
                            border: Border.all(color: scheme.primary, width: 2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 24,
                    child: Text(
                      waiting
                          ? 'Too many attempts. Try again in ${seconds}s'
                          : (_message ?? ''),
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _keypad(waiting),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in children)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: c,
            ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 72, height: 72, child: Center(child: child)),
        ),
      ),
    );
  }
}
