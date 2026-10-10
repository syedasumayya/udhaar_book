import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/date_format.dart';
import '../../core/money.dart';
import '../../core/widgets.dart';
import '../../data/models/loan.dart';
import '../../data/models/person.dart';
import '../../data/models/repayment.dart';
import '../../domain/balance.dart';
import '../../domain/summary_text.dart';
import '../../providers.dart';
import '../loans/add_loan_page.dart';
import '../loans/loan_detail_page.dart';
import 'add_person_dialog.dart';
import 'share_summary_sheet.dart';

class PersonDetailPage extends ConsumerWidget {
  const PersonDetailPage({super.key, required this.personId});

  final String personId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this person?'),
        content: const Text(
          'All their loans and repayments will be deleted too. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final notifier = ref.read(appDataProvider.notifier);
    Navigator.pop(context);
    await notifier.deletePerson(personId);
  }

  Future<void> _settleAll(
    BuildContext context,
    WidgetRef ref,
    AppData data,
    String name,
  ) async {
    final open = data
        .loansFor(personId)
        .where((l) => Balance.remaining(l, data.repayments) > 0)
        .length;
    if (open == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nothing to settle.')));
      return;
    }

    final t = data.totalsFor(personId);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle all?'),
        content: Text(
          '$open open loan${open == 1 ? '' : 's'} will be marked as fully '
          'paid today.\n\n'
          '$name owes you ${Money.format(t.owedToMe)}\n'
          'You owe $name ${Money.format(t.iOwe)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Settle all'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final n = await ref.read(appDataProvider.notifier).settleAll(personId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settled $n loan${n == 1 ? '' : 's'}.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider).value;
    final person = data?.personById(personId);
    if (data == null || person == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final loans = data.loansFor(personId);

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Settle all',
            icon: const Icon(Icons.done_all),
            onPressed: () => _settleAll(context, ref, data, person.name),
          ),
          IconButton(
            tooltip: 'Edit person',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showPersonDialog(context, ref, existing: person),
          ),
          IconButton(
            tooltip: 'Delete person',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddLoanPage(personId: personId)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add loan'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    net == 0
                        ? 'All settled'
                        : net > 0
                        ? '${person.name} owes you'
                        : 'You owe ${person.name}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Money.format(net.abs()),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: net >= 0 ? scheme.primary : scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (person.phone != null) ...[
                    const SizedBox(height: 8),
                    Text(person.phone!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'They owe you',
                  value: Money.format(totals.owedToMe),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'You owe them',
                  value: Money.format(totals.iOwe),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share summary'),
              ),
              OutlinedButton.icon(
                onPressed: onSettle,
                icon: const Icon(Icons.done_all),
                label: const Text('Settle all'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan, required this.repayments});

  final Loan loan;
  final List<Repayment> repayments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lent = loan.direction == LoanDirection.lent;
    final paid = Balance.paid(loan, repayments);
    final left = Balance.remaining(loan, repayments);
    final overdue = Balance.isOverdue(loan, repayments);
    final progress =
        loan.principal == 0 ? 0.0 : (paid / loan.principal).clamp(0.0, 1.0);
    final accent = lent ? context.positiveColor : context.negativeColor;

    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoanDetailPage(loanId: loan.id)),
      ),
      leading: CircleAvatar(
        child: Icon(lent ? Icons.arrow_upward : Icons.arrow_downward),
      ),
      title: Text(Money.format(loan.principal)),
      subtitle: Text(subtitle.toString()),
      trailing: left == 0
          ? const Chip(label: Text('Paid'))
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(left),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  overdue ? 'Overdue' : 'left',
                  style: TextStyle(
                    color: overdue ? scheme.error : scheme.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
    );
  }
}