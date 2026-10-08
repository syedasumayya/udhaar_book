import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../lock_provider.dart';

List<TextInputFormatter> get _pinFormatters => [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(LockNotifier.maxPinLength),
];

const _rangeText =
    '${LockNotifier.minPinLength} to ${LockNotifier.maxPinLength} digits';

/// Asks for one PIN. Returns it, or null if cancelled.
Future<String?> showEnterPinDialog(
  BuildContext context, {
  required String title,
}) => showDialog<String>(
  context: context,
  builder: (_) => _EnterPinDialog(title: title),
);

/// Asks for a new PIN twice. Returns it, or null if cancelled.
Future<String?> showNewPinDialog(
  BuildContext context, {
  required String title,
}) => showDialog<String>(
  context: context,
  builder: (_) => _NewPinDialog(title: title),
);

class _EnterPinDialog extends StatefulWidget {
  const _EnterPinDialog({required this.title});

  final String title;

  @override
  State<_EnterPinDialog> createState() => _EnterPinDialogState();
}

class _EnterPinDialogState extends State<_EnterPinDialog> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pin.text.length < LockNotifier.minPinLength) {
      setState(() => _error = 'Enter your PIN ($_rangeText)');
      return;
    }
    Navigator.pop(context, _pin.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _pin,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: _pinFormatters,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(labelText: 'PIN', errorText: _error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}

class _NewPinDialog extends StatefulWidget {
  const _NewPinDialog({required this.title});

  final String title;

  @override
  State<_NewPinDialog> createState() => _NewPinDialogState();
}

class _NewPinDialogState extends State<_NewPinDialog> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pin.text.length < LockNotifier.minPinLength) {
      setState(() => _error = 'Use $_rangeText');
      return;
    }
    if (_pin.text != _confirm.text) {
      setState(() => _error = 'PINs do not match');
      return;
    }
    Navigator.pop(context, _pin.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pin,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: _pinFormatters,
            decoration: const InputDecoration(
              labelText: 'New PIN',
              helperText: _rangeText,
            ),
          ),
          TextField(
            controller: _confirm,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: _pinFormatters,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Confirm PIN',
              errorText: _error,
            ),
          ),
        ],
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
