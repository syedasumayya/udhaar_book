import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/person.dart';
import '../../domain/summary_text.dart';

Future<void> showShareSummarySheet(
  BuildContext context, {
  required Person person,
  required String text,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ShareSheet(person: person, text: text),
  );
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.person, required this.text});

  final Person person;
  final String text;

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Summary copied.')));
  }

  Future<void> _whatsapp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    var opened = false;
    try {
      opened = await launchUrl(
        SummaryText.whatsappUri(person.phone, text),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (opened) {
      navigator.pop();
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp. Use Copy instead.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share summary with ${person.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(text),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _whatsapp(context),
                    icon: const Icon(Icons.send),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}