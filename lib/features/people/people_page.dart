import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/money.dart';
import '../../providers.dart';
import 'add_person_dialog.dart';
import 'person_detail_page.dart';

class PeoplePage extends ConsumerWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appDataProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddPersonDialog(context, ref),
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

          final people = [...data.people]
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: people.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
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
                  child: Text(p.name.characters.first.toUpperCase()),
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
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PersonDetailPage(personId: p.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
