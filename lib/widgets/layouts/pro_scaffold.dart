import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProScaffold extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const ProScaffold({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Pro theme is dense. We use a smaller BottomNavigationBar.
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onDestinationSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
          showUnselectedLabels: false, // Dense look
          showSelectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined, size: 20),
              activeIcon: Icon(Icons.dashboard, size: 20),
              label: 'Dash',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined, size: 20), // Budget
              activeIcon: Icon(Icons.description, size: 20),
              label: 'Orçamentos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle, size: 32), // Prominent Add
              activeIcon: Icon(Icons.add_circle, size: 32),
              label: 'Novo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 20),
              activeIcon: Icon(Icons.people, size: 20),
              label: 'Clientes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined, size: 20),
              activeIcon: Icon(Icons.settings, size: 20),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
      floatingActionButton:
          selectedIndex ==
              2 // If "New" is selected or handled via FAB
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/budget/new'),
              mini: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
