import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/date_format.dart';
import '../../core/money.dart';
import '../../data/models/loan.dart';
import '../../domain/balance.dart';
import '../../providers.dart';
import 'add_repayment_dialog.dart';

class LoanDetailPage extends ConsumerWidget {
  const LoanDetailPage({super.key, required this.loanId});

  final String loanId;

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String message,
    String action,
  ) async {
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

  Future<void> _addPayment(
    BuildContext context,
    WidgetRef ref,
    Loan loan,
    int left,
  ) async {
    final result = await showAddRepaymentDialog(
      context,
      maxAmount: left,
      minDate: loan.date,
    );
    if (result == null) return;
    await ref
        .read(appDataProvider.notifier)
        .addRepayment(
          loanId: loan.id,
          amount: result.amount,
          date: result.date,
          note: result.note,
        );
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    Loan loan,
    int left,
  ) async {
    final ok = await _confirm(
      context,
      'Mark as fully paid?',
      'This records a payment of ${Money.format(left)} dated today.',
      'Mark paid',
    );
    if (!ok) return;
    final today = DateUtils.dateOnly(DateTime.now());
    final date = today.isBefore(loan.date) ? loan.date : today;
    await ref
        .read(appDataProvider.notifier)
        .addRepayment(
          loanId: loan.id,
          amount: left,
          date: date,
          note: 'Marked as fully paid',
        );
  }

  Future<void> _deleteLoan(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(
      context,
      'Delete this loan?',
      'Its payment history will be deleted too. This cannot be undone.',
      'Delete',
    );
    if (!ok || !context.mounted) return;
    final notifier = ref.read(appDataProvider.notifier);
    Navigator.pop(context);
    await notifier.deleteLoan(loanId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider).value;
    final loan = data?.loanById(loanId);
    if (data == null || loan == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final scheme = Theme.of(context).colorScheme;
    final person = data.personById(loan.personId);
    final reps = data.repaymentsFor(loanId);
    final paid = Balance.paid(loan, reps);
    final left = Balance.remaining(loan, reps);
    final overdue = Balance.isOverdue(loan, reps);
    final lent = loan.direction == LoanDirection.lent;
    final progress = loan.principal == 0
        ? 0.0
        : (paid / loan.principal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(person?.name ?? 'Loan'),
        actions: [
          IconButton(
            tooltip: 'Delete loan',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteLoan(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lent ? 'You gave' : 'You took',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    Money.format(loan.principal),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress, minHeight: 8),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paid ${Money.format(paid)}'),
                      Text(
                        left == 0 ? 'Fully paid' : 'Left ${Money.format(left)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: left == 0
                              ? scheme.primary
                              : overdue
                              ? scheme.error
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Text('Date: ${formatDate(loan.date)}'),
                  if (loan.dueDate != null)
                    Text(
                      'Due: ${formatDate(loan.dueDate!)}'
                      '${overdue ? '  (overdue)' : ''}',
                      style: TextStyle(color: overdue ? scheme.error : null),
                    ),
                  if (loan.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(loan.note),
                  ],
                ],
              ),
            ),
          ),
          if (left > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _addPayment(context, ref, loan, left),
                      icon: const Icon(Icons.add),
                      label: const Text('Add payment'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markPaid(context, ref, loan, left),
                      icon: const Icon(Icons.check),
                      label: const Text('Mark paid'),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Payment history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (reps.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No payments yet.'),
            ),
          for (final r in reps)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
              title: Text(Money.format(r.amount)),
              subtitle: Text(
                r.note.isEmpty
                    ? formatDate(r.date)
                    : '${formatDate(r.date)} • ${r.note}',
              ),
              trailing: IconButton(
                tooltip: 'Delete payment',
                icon: const Icon(Icons.close),
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    'Delete this payment?',
                    'The loan balance will go back up by '
                        '${Money.format(r.amount)}.',
                    'Delete',
                  );
                  if (!ok) return;
                  await ref
                      .read(appDataProvider.notifier)
                      .deleteRepayment(r.id);
                },
              ),
            ),
        ],
      ),
    );
  }
}
