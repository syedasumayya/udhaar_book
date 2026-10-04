import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/money.dart';
import '../../domain/balance.dart';
import '../../providers.dart';

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
          final overdue = data.loans
              .where((l) => Balance.isOverdue(l, data.repayments))
              .length;

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
              if (overdue > 0)
                Card(
                  color: scheme.errorContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: scheme.onErrorContainer,
                    ),
                    title: Text(
                      '$overdue overdue loan${overdue == 1 ? '' : 's'}',
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
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
