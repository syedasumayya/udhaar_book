import 'package:flutter/material.dart';
import '../dashboard/dashboard_page.dart';
import '../people/people_page.dart';
import '../settings/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _Item {
  const _Item(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _items = [
    _Item('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _Item('People', Icons.people_outline, Icons.people),
    _Item('Settings', Icons.settings_outlined, Icons.settings),
  ];

  static const _pages = [DashboardPage(), PeoplePage(), SettingsPage()];

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: _Brand(),
              ),
              destinations: [
                for (final item in _items)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (final item in _items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.account_balance_wallet_outlined,
        color: scheme.onPrimary,
      ),
    );
  }
}