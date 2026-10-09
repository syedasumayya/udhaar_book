import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/date_format.dart';
import '../../core/money.dart';
import '../../data/models/loan.dart';
import '../../data/models/person.dart';
import '../../domain/balance.dart';
import '../../providers.dart';
import '../loans/loan_detail_page.dart';
import '../people/person_detail_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appDataProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong: $e')),
        data: (data) {
          final t = data.totals;
          final overdue = data.overdueLoans();
          final upcoming = data.upcomingLoans();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatCard(
                label: 'People owe you',
                amount: t.owedToMe,
                color: scheme.primary,
                icon: Icons.south_west,
              ),
              _StatCard(
                label: 'You owe',
                amount: t.iOwe,
                color: scheme.error,
                icon: Icons.north_east,
              ),
              _StatCard(
                label: t.net >= 0 ? 'Net: you are owed' : 'Net: you owe',
                amount: t.net.abs(),
                color: t.net >= 0 ? scheme.primary : scheme.error,
                icon: Icons.account_balance_wallet_outlined,
              ),
              if (data.people.isEmpty) const _WelcomeCard(),
              _TopBalances(data: data),
              if (overdue.isNotEmpty)
                _DueSection(
                  title: 'Overdue (${overdue.length})',
                  color: scheme.error,
                  loans: overdue,
                  data: data,
                ),
              if (upcoming.isNotEmpty)
                _DueSection(
                  title: 'Due in the next 7 days (${upcoming.length})',
                  color: scheme.primary,
                  loans: upcoming,
                  data: data,
                ),
              if (overdue.isEmpty && upcoming.isEmpty && data.loans.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Nothing overdue or due soon. 🎉'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    Money.format(amount),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Welcome to Udhaar Book.\n\n'
          'Open the People tab, add someone, then record a loan. '
          'Your totals will show up here.',
        ),
      ),
    );
  }
}

class _TopBalances extends StatelessWidget {
  const _TopBalances({required this.data});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final rows = <({Person person, int net})>[];
    for (final p in data.people) {
      final net = data.totalsFor(p.id).net;
      if (net != 0) rows.add((person: p, net: net));
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    rows.sort((a, b) => b.net.abs().compareTo(a.net.abs()));
    final top = rows.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(
            'Biggest balances',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < top.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PersonDetailPage(personId: top[i].person.id),
                    ),
                  ),
                  leading: CircleAvatar(
                    child: Text(
                        top[i].person.name.characters.first.toUpperCase()),
                  ),
                  title: Text(top[i].person.name),
                  subtitle: Text(top[i].net > 0 ? 'Owes you' : 'You owe'),
                  trailing: Text(
                    Money.format(top[i].net.abs()),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: top[i].net > 0 ? scheme.primary : scheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DueSection extends StatelessWidget {
  const _DueSection({
    required this.title,
    required this.color,
    required this.loans,
    required this.data,
  });

  final String title;
  final Color color;
  final List<Loan> loans;
  final AppData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < loans.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _DueTile(loan: loans[i], data: data),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DueTile extends StatelessWidget {
  const _DueTile({required this.loan, required this.data});

  final Loan loan;
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final name = data.personById(loan.personId)?.name ?? 'Unknown';
    final lent = loan.direction == LoanDirection.lent;
    final left = Balance.remaining(loan, data.repayments);

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoanDetailPage(loanId: loan.id)),
      ),
      leading: CircleAvatar(
        child: Icon(lent ? Icons.arrow_upward : Icons.arrow_downward),
      ),
      title: Text(name),
      subtitle: Text(
          '${lent ? 'Owes you' : 'You owe'} • due ${formatDate(loan.dueDate!)}'),
      trailing: Text(
        Money.format(left),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
