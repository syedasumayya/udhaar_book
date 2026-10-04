import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/date_format.dart';
import '../../core/money.dart';

typedef RepaymentInput = ({int amount, DateTime date, String note});

Future<RepaymentInput?> showAddRepaymentDialog(
  BuildContext context, {
  required int maxAmount,
  required DateTime minDate,
}) {
  return showDialog<RepaymentInput>(
    context: context,
    builder: (_) => _AddRepaymentDialog(maxAmount: maxAmount, minDate: minDate),
  );
}

class _AddRepaymentDialog extends StatefulWidget {
  const _AddRepaymentDialog({required this.maxAmount, required this.minDate});

  final int maxAmount;
  final DateTime minDate;

  @override
  State<_AddRepaymentDialog> createState() => _AddRepaymentDialogState();
}

class _AddRepaymentDialogState extends State<_AddRepaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    final min = DateUtils.dateOnly(widget.minDate);
    _date = today.isBefore(min) ? min : today;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _maxAsText => widget.maxAmount % 100 == 0
      ? '${widget.maxAmount ~/ 100}'
      : (widget.maxAmount / 100).toStringAsFixed(2);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateUtils.dateOnly(widget.minDate),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      amount: Money.parse(_amount.text)!,
      date: _date,
      note: _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add payment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rs ',
                  helperText: 'Remaining: ${Money.format(widget.maxAmount)}',
                  suffixIcon: TextButton(
                    onPressed: () => setState(() => _amount.text = _maxAsText),
                    child: const Text('Full'),
                  ),
                ),
                validator: (v) {
                  final minor = Money.parse(v ?? '');
                  if (minor == null || minor <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (minor > widget.maxAmount) {
                    return 'Cannot exceed ${Money.format(widget.maxAmount)}';
                  }
                  return null;
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Date'),
                subtitle: Text(formatDate(_date)),
                onTap: _pickDate,
              ),
              TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
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
