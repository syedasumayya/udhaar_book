import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/person.dart';
import '../../providers.dart';

/// Pass [existing] to edit a person, leave it out to add a new one.
Future<void> showPersonDialog(
  BuildContext context,
  WidgetRef ref, {
  Person? existing,
}) async {
  final result = await showDialog<({String name, String? phone})>(
    context: context,
    builder: (_) => _PersonDialog(existing: existing),
  );
  if (result == null) return;

  final notifier = ref.read(appDataProvider.notifier);
  if (existing == null) {
    await notifier.addPerson(name: result.name, phone: result.phone);
  } else {
    await notifier.updatePerson(
      Person(
        id: existing.id,
        name: result.name,
        phone: result.phone,
        createdAt: existing.createdAt,
      ),
    );
  }
}

class _PersonDialog extends StatefulWidget {
  const _PersonDialog({this.existing});

  final Person? existing;

  @override
  State<_PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<_PersonDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _phone = TextEditingController(text: widget.existing?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phone.text.trim();
    Navigator.pop(context, (
      name: _name.text.trim(),
      phone: phone.isEmpty ? null : phone,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add person' : 'Edit person'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
