import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/date_format.dart';
import '../../core/money.dart';
import '../../core/widgets.dart';
import '../../data/models/loan.dart';
import '../../domain/balance.dart';
import '../../domain/monthly_activity.dart';
import '../../providers.dart';
import '../loans/loan_detail_page.dart';
import '../people/person_detail_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), centerTitle: false),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong: $e')),
        data: (data) => ContentWidth(child: _DashboardBody(data: data)),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    final t = data.totals;
    final overdue = data.overdueLoans();
    final upcoming = data.upcomingLoans();
    final open = data.loans
        .where((l) => Balance.remaining(l, data.repayments) > 0)
        .length;
    final months = MonthlyActivity.lastMonths(data.loans);
    final hasActivity = months.any((m) => m.lent > 0 || m.borrowed > 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _HeroCard(
          totals: t,
          openLoans: open,
          overdue: overdue.length,
          people: data.people.length,
        ),
        if (data.people.isEmpty) ...[
          const SizedBox(height: 12),
          const _WelcomeCard(),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'People owe you',
                amount: t.owedToMe,
                color: context.positiveColor,
                icon: Icons.south_west,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: 'You owe',
                amount: t.iOwe,
                color: context.negativeColor,
                icon: Icons.north_east,
              ),
            ),
          ],
        ),
        const SectionHeader('Last 6 months'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Loans by month',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  _LegendDot(color: context.positiveColor, label: 'You gave'),
                  const SizedBox(width: 12),
                  _LegendDot(color: context.negativeColor, label: 'You took'),
                ],
              ),
              const SizedBox(height: 16),
              if (hasActivity)
                _ActivityChart(months: months)
              else
                Text(
                  'Loans you add will show up here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
        if (overdue.isNotEmpty) ...[
          SectionHeader('Overdue (${overdue.length})'),
          _DueList(loans: overdue, data: data),
        ],
        if (upcoming.isNotEmpty) ...[
          SectionHeader('Due in the next 7 days (${upcoming.length})'),
          _DueList(loans: upcoming, data: data),
        ],
        if (overdue.isEmpty && upcoming.isEmpty && data.loans.isNotEmpty) ...[
          const SectionHeader('Needs attention'),
          AppCard(
            child: Row(
              children: [
                IconBadge(
                  icon: Icons.check_circle_outline,
                  color: context.positiveColor,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Nothing overdue or due soon.'),
                ),
              ],
            ),
          ),
        ],
        _TopBalances(data: data),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.totals,
    required this.openLoans,
    required this.overdue,
    required this.people,
  });

  final Totals totals;
  final int openLoans;
  final int overdue;
  final int people;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = totals.net;
    final total = totals.owedToMe + totals.iOwe;
    final caption = net == 0
        ? 'You are all square'
        : net > 0
            ? 'Overall, you are owed'
            : 'Overall, you owe';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net balance',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.format(net.abs()),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          Text(
            caption,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: totals.owedToMe / total,
                minHeight: 8,
                backgroundColor: Colors.white24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(totals.owedToMe * 100 / total).round()}% of open balances '
              'are owed to you',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroStat(label: 'Open loans', value: '$openLoans'),
              _HeroStat(label: 'Overdue', value: '$overdue'),
              _HeroStat(label: 'People tracked', value: '$people'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: Icons.waving_hand_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Welcome to Udhaar Book.\n\n'
              'Open the People tab, add someone, then record a loan. '
              'Your totals will show up here.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Money.format(amount),
              style: theme.textTheme.titleLarge?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.months});

  final List<MonthActivity> months;

  static const _chartHeight = 110.0;

  @override
  Widget build(BuildContext context) {
    final maxValue = months.fold<int>(
      0,
      (m, a) => math.max(m, math.max(a.lent, a.borrowed)),
    );

    double barHeight(int v) =>
        v == 0 ? 0 : math.max(4.0, v / maxValue * _chartHeight);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final m in months)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: _chartHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Bar(height: barHeight(m.lent), color: context.positiveColor),
                      const SizedBox(width: 4),
                      _Bar(
                        height: barHeight(m.borrowed),
                        color: context.negativeColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('MMM').format(m.month),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

class _DueList extends StatelessWidget {
  const _DueList({required this.loans, required this.data});

  final List<Loan> loans;
  final AppData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < loans.length; i++) ...[
            if (i > 0) const Divider(),
            _DueRow(loan: loans[i], data: data),
          ],
        ],
      ),
    );
  }
}

class _DueRow extends StatelessWidget {
  const _DueRow({required this.loan, required this.data});

  final Loan loan;
  final AppData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = data.personById(loan.personId)?.name ?? 'Unknown';
    final lent = loan.direction == LoanDirection.lent;
    final left = Balance.remaining(loan, data.repayments);
    final days = daysBetween(DateTime.now(), loan.dueDate!);

    final String pillText;
    final Color pillColor;
    if (days < 0) {
      pillText = '${-days}d overdue';
      pillColor = context.negativeColor;
    } else if (days == 0) {
      pillText = 'Due today';
      pillColor = context.warningColor;
    } else {
      pillText = 'In ${days}d';
      pillColor = theme.colorScheme.primary;
    }

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoanDetailPage(loanId: loan.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            PersonAvatar(name: name, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${lent ? 'Owes you' : 'You owe'} • '
                    'due ${formatDate(loan.dueDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(left),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                StatusPill(pillText, color: pillColor),
              ],
            ),
          ],
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
    final theme = Theme.of(context);

    final rows = <({String id, String name, int net})>[];
    for (final p in data.people) {
      final net = data.totalsFor(p.id).net;
      if (net != 0) rows.add((id: p.id, name: p.name, net: net));
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    rows.sort((a, b) => b.net.abs().compareTo(a.net.abs()));
    final top = rows.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Biggest balances'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < top.length; i++) ...[
                if (i > 0) const Divider(),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersonDetailPage(personId: top[i].id),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        PersonAvatar(name: top[i].name, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                top[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                top[i].net > 0 ? 'Owes you' : 'You owe',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Money.format(top[i].net.abs()),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: top[i].net > 0
                                ? context.positiveColor
                                : context.negativeColor,
                          ),
                        ),
                      ],
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