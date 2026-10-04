import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/date_format.dart';
import '../../core/money.dart';
import '../../data/models/loan.dart';
import '../../providers.dart';

/// Pass [existing] to edit a loan, leave it out to add a new one.
class AddLoanPage extends ConsumerStatefulWidget {
  const AddLoanPage({super.key, required this.personId, this.existing});

  final String personId;
  final Loan? existing;

  @override
  ConsumerState<AddLoanPage> createState() => _AddLoanPageState();
}

class _AddLoanPageState extends ConsumerState<AddLoanPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;

  late LoanDirection _direction;
  late DateTime _date;
  DateTime? _dueDate;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _direction = e?.direction ?? LoanDirection.lent;
    _date = e?.date ?? DateUtils.dateOnly(DateTime.now());
    _dueDate = e?.dueDate;
    _amount = TextEditingController(
      text: e == null ? '' : _toText(e.principal),
    );
    _note = TextEditingController(text: e?.note ?? '');
  }

  static String _toText(int minor) =>
      minor % 100 == 0 ? '${minor ~/ 100}' : (minor / 100).toStringAsFixed(2);

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool due}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: due ? (_dueDate ?? _date) : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (due) {
        _dueDate = picked;
      } else {
        _date = picked;
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate != null && _dueDate!.isBefore(_date)) {
      _showError('Due date cannot be before the loan date');
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(appDataProvider.notifier);
    final principal = Money.parse(_amount.text)!;

    try {
      if (_isEdit) {
        final e = widget.existing!;
        await notifier.updateLoan(
          Loan(
            id: e.id,
            personId: e.personId,
            direction: _direction,
            principal: principal,
            date: _date,
            dueDate: _dueDate,
            note: _note.text.trim(),
            createdAt: e.createdAt,
          ),
        );
      } else {
        await notifier.addLoan(
          personId: widget.personId,
          direction: _direction,
          principal: principal,
          date: _date,
          dueDate: _dueDate,
          note: _note.text,
        );
      }
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e.message.toString());
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit loan' : 'Add loan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<LoanDirection>(
              segments: const [
                ButtonSegment(
                  value: LoanDirection.lent,
                  label: Text('I gave'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: LoanDirection.borrowed,
                  label: Text('I took'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amount,
              autofocus: !_isEdit,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'Rs ',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final minor = Money.parse(v ?? '');
                if (minor == null || minor <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Loan date'),
              subtitle: Text(formatDate(_date)),
              onTap: () => _pickDate(due: false),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy),
              title: const Text('Due date (optional)'),
              subtitle: Text(
                _dueDate == null ? 'Not set' : formatDate(_dueDate!),
              ),
              trailing: _dueDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    ),
              onTap: () => _pickDate(due: true),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_isEdit ? 'Save changes' : 'Save loan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
