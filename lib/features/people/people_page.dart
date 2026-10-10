import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/money.dart';
import '../../core/widgets.dart';
import '../../data/models/person.dart';
import '../../domain/balance.dart';
import '../../providers.dart';
import 'add_person_dialog.dart';
import 'person_detail_page.dart';

enum _Filter { all, owesYou, youOwe, settled }

class PeoplePage extends ConsumerStatefulWidget {
  const PeoplePage({super.key});

  @override
  ConsumerState<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends ConsumerState<PeoplePage> {
  String _query = '';
  _Filter _filter = _Filter.all;

  static const _labels = {
    _Filter.all: 'All',
    _Filter.owesYou: 'Owes you',
    _Filter.youOwe: 'You owe',
    _Filter.settled: 'Settled',
  };

  bool _matchesFilter(int net) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.owesYou:
        return net > 0;
      case _Filter.youOwe:
        return net < 0;
      case _Filter.settled:
        return net == 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(appDataProvider);
    final scheme = Theme.of(context).colorScheme;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('People'), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPersonDialog(context, ref),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add person'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong: $e')),
        data: (data) {
          if (data.people.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No one here yet',
              message: 'Add the people you lend to or borrow from, '
                  'then record your first loan.',
            );
          }

          final q = _query.trim().toLowerCase();
          final people = data.people.where((p) {
            final matchesQuery = q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                (p.phone ?? '').contains(q);
            return matchesQuery && _matchesFilter(data.totalsFor(p.id).net);
          }).toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

          return ContentWidth(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search name or phone',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: scheme.surfaceContainerLowest,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: border(scheme.outlineVariant),
                      enabledBorder: border(scheme.outlineVariant),
                      focusedBorder: border(scheme.primary),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      for (final f in _Filter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_labels[f]!),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: people.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'No matching people',
                          message: 'Try a different name or filter.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: people.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => _PersonCard(
                            person: people[i],
                            totals: data.totalsFor(people[i].id),
                            loanCount: data.loansFor(people[i].id).length,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.person,
    required this.totals,
    required this.loanCount,
  });

  final Person person;
  final Totals totals;
  final int loanCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = totals.net;
    final color = net > 0 ? context.positiveColor : context.negativeColor;
    final subtitle = person.phone ??
        (loanCount == 0
            ? 'No loans yet'
            : '$loanCount loan${loanCount == 1 ? '' : 's'}');

    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PersonDetailPage(personId: person.id),
        ),
      ),
      child: Row(
        children: [
          PersonAvatar(name: person.name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (net == 0)
            StatusPill('Settled', color: theme.colorScheme.outline)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Money.format(net.abs()),
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  net > 0 ? 'Owes you' : 'You owe',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}