import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lock_provider.dart';
import 'lock_screen.dart';

/// Sits above the whole app. Shows the lock screen over it while locked
/// and locks again whenever the app goes to the background.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      ref.read(lockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(lockProvider.select((s) => s.locked));

    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(
          excluding: locked,
          child: ExcludeSemantics(excluding: locked, child: widget.child),
        ),
        if (locked) const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}
