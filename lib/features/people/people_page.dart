import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/money.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('People')),
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No one here yet.\nTap "Add person" to start.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final q = _query.trim().toLowerCase();
          final people =
              data.people.where((p) {
                final matchesQuery =
                    q.isEmpty ||
                    p.name.toLowerCase().contains(q) ||
                    (p.phone ?? '').contains(q);
                return matchesQuery && _matchesFilter(data.totalsFor(p.id).net);
              }).toList()..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search name or phone',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
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
                    ? const Center(child: Text('No matching people.'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: people.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final p = people[i];
                          final net = data.totalsFor(p.id).net;
                          final color = net > 0
                              ? scheme.primary
                              : net < 0
                              ? scheme.error
                              : scheme.outline;

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                p.name.characters.first.toUpperCase(),
                              ),
                            ),
                            title: Text(p.name),
                            subtitle: Text(
                              net == 0
                                  ? 'Settled'
                                  : net > 0
                                  ? 'Owes you'
                                  : 'You owe',
                            ),
                            trailing: Text(
                              net == 0 ? '' : Money.format(net.abs()),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PersonDetailPage(personId: p.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
