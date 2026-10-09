import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers.dart';

final packageInfoProvider = FutureProvider<PackageInfo?>((ref) async {
  try {
    return await PackageInfo.fromPlatform();
  } catch (_) {
    return null; // the About screen simply hides the version
  }
});

class AboutTile extends ConsumerWidget {
  const AboutTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider).value;
    final info = ref.watch(packageInfoProvider).value;

    final lines = <String>[
      if (info != null) 'Version ${info.version}',
      if (data != null)
        '${data.people.length} people • ${data.loans.length} loans '
            '• ${data.repayments.length} payments',
    ];

    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('About Udhaar Book'),
      subtitle: lines.isEmpty ? null : Text(lines.join('\n')),
      isThreeLine: lines.length > 1,
      onTap: () => showAboutDialog(
        context: context,
        applicationName: 'Udhaar Book',
        applicationVersion: info?.version,
        applicationLegalese: 'Released under the MIT License.',
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'A private ledger for money you lend or borrow. '
              'Your data stays on this device.',
            ),
          ),
        ],
      ),
    );
  }
}