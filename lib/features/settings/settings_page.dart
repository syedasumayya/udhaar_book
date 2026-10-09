import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/backup.dart';
import '../../domain/csv_report.dart';
import '../../lock_provider.dart';
import '../../providers.dart';
import '../../settings_provider.dart';
import 'about_tile.dart';
import 'pin_dialogs.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final data = ref.read(appDataProvider).value;
    if (data == null) return;
    if (data.loans.isEmpty) {
      _toast(context, 'Nothing to export yet.');
      return;
    }
    final csv = CsvReport.loans(
      people: data.people,
      loans: data.loans,
      repayments: data.repayments,
    );
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    _toast(context, 'CSV copied. Paste it into Notepad and save as a .csv file.');
  }

  Future<void> _copyBackup(BuildContext context, WidgetRef ref) async {
    final data = ref.read(appDataProvider).value;
    if (data == null) return;
    final text = BackupService.encode(
      people: data.people,
      loans: data.loans,
      repayments: data.repayments,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    _toast(context, 'Backup copied. Save it somewhere safe (a note, an email).');
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _RestoreDialog(),
    );
    if (text == null || !context.mounted) return;

    final BackupData backup;
    try {
      backup = BackupService.decode(text);
    } on FormatException catch (e) {
      _toast(context, e.message);
      return;
    }

    final ok = await _confirm(
      context,
      title: 'Replace all current data?',
      message: 'This backup has ${backup.people.length} people, '
          '${backup.loans.length} loans and ${backup.repayments.length} '
          'payments. Your current data will be replaced.',
      action: 'Restore',
    );
    if (!ok || !context.mounted) return;

    await ref.read(appDataProvider.notifier).replaceAll(
          people: backup.people,
          loans: backup.loans,
          repayments: backup.repayments,
        );
    if (!context.mounted) return;
    _toast(context, 'Backup restored.');
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      title: 'Delete all data?',
      message: 'Every person, loan and payment will be deleted. '
          'Copy a backup first if you might need it. This cannot be undone.',
      action: 'Delete everything',
    );
    if (!ok || !context.mounted) return;

    await ref.read(appDataProvider.notifier).clearAll();
    if (!context.mounted) return;
    _toast(context, 'All data deleted.');
  }

  // ---- PIN lock ----
  String _waitText(Duration d) {
    final s = (d.inMilliseconds / 1000).ceil();
    return 'Too many wrong attempts. Try again in $s seconds.';
  }

  Future<void> _setPin(BuildContext context, WidgetRef ref) async {
    final pin = await showNewPinDialog(context, title: 'Set PIN');
    if (pin == null || !context.mounted) return;
    await ref.read(lockProvider.notifier).setPin(pin);
    if (!context.mounted) return;
    _toast(context, 'PIN lock is on. Keep a backup in case you forget it.');
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(lockProvider.notifier);
    if (notifier.waitLeft > Duration.zero) {
      _toast(context, _waitText(notifier.waitLeft));
      return;
    }
    final current =
        await showEnterPinDialog(context, title: 'Enter current PIN');
    if (current == null || !context.mounted) return;
    final next = await showNewPinDialog(context, title: 'New PIN');
    if (next == null || !context.mounted) return;

    final ok = await notifier.changePin(current, next);
    if (!context.mounted) return;
    _toast(context, ok ? 'PIN changed.' : 'Wrong current PIN.');
  }

  Future<void> _removePin(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(lockProvider.notifier);
    if (notifier.waitLeft > Duration.zero) {
      _toast(context, _waitText(notifier.waitLeft));
      return;
    }
    final current =
        await showEnterPinDialog(context, title: 'Enter PIN to remove it');
    if (current == null || !context.mounted) return;

    final ok = await notifier.removePin(current);
    if (!context.mounted) return;
    _toast(context, ok ? 'PIN lock removed.' : 'Wrong PIN.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final lock = ref.watch(lockProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _Header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ),
          const _Header('Security'),
          if (!lock.hasPin)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Set PIN lock'),
              subtitle: const Text('Ask for a PIN when the app is opened'),
              onTap: () => _setPin(context, ref),
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.lock_clock),
              title: const Text('Lock now'),
              onTap: () => ref.read(lockProvider.notifier).lock(),
            ),
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change PIN'),
              onTap: () => _changePin(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.lock_open),
              title: const Text('Remove PIN lock'),
              onTap: () => _removePin(context, ref),
            ),
          ],
          const _Header('Backup and export'),
          ListTile(
            leading: const Icon(Icons.copy_all_outlined),
            title: const Text('Copy backup'),
            subtitle: const Text('Your whole ledger as text'),
            onTap: () => _copyBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore backup'),
            subtitle: const Text('Paste a backup you copied earlier'),
            onTap: () => _restore(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.table_view_outlined),
            title: const Text('Export loans as CSV'),
            subtitle: const Text('For Excel or Google Sheets'),
            onTap: () => _exportCsv(context, ref),
          ),
          const _Header('Danger zone'),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
            title: Text('Delete all data',
                style: TextStyle(color: scheme.error)),
            onTap: () => _clearAll(context, ref),
          ),
          const _Header('About'),
          const AboutTile(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog();

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restore backup'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste the backup text you copied earlier.'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 8,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{ "app": "udhaar_book", ... }',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            Navigator.pop(context, text);
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}