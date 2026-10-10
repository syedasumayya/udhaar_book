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
          'All their loans and repayments will be deleted too. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to settle.')),
      );
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
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _Header(
              person: person,
              totals: data.totalsFor(personId),
              onShare: () => showShareSummarySheet(
                context,
                person: person,
                text: SummaryText.forPerson(
                  person: person,
                  loans: loans,
                  repayments: data.repayments,
                ),
              ),
              onSettle: () => _settleAll(context, ref, data, person.name),
            ),
            SectionHeader(
              'Loans',
              trailing: Text(
                '${loans.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            if (loans.isEmpty)
              const AppCard(
                child: Text('No loans yet. Tap "Add loan" to record one.'),
              ),
            for (final loan in loans)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LoanCard(loan: loan, repayments: data.repayments),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.person,
    required this.totals,
    required this.onShare,
    required this.onSettle,
  });

  final Person person;
  final Totals totals;
  final VoidCallback onShare;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = totals.net;
    final label = net == 0
        ? 'All settled'
        : net > 0
            ? '${person.name} owes you'
            : 'You owe ${person.name}';

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PersonAvatar(name: person.name, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (person.phone != null)
                      Text(
                        person.phone!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.format(net.abs()),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: net == 0
                    ? theme.colorScheme.onSurface
                    : net > 0
                        ? context.positiveColor
                        : context.negativeColor,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: lent ? Icons.arrow_upward : Icons.arrow_downward,
                color: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Money.format(loan.principal),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      '${lent ? 'You gave' : 'You took'} • '
                      '${formatDate(loan.date)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (left == 0)
                StatusPill('Paid', color: context.positiveColor)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Money.format(left),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    if (overdue)
                      StatusPill('Overdue', color: context.negativeColor)
                    else
                      Text(
                        'left',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, minHeight: 6),
          ),
          if (loan.dueDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Due ${formatDate(loan.dueDate!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: overdue
                    ? context.negativeColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}