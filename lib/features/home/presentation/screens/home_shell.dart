import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/models/app_user.dart';

class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  int _selectedIndex(BuildContext context, bool isB2B) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/home')) return 0;
    
    if (isB2B) {
      if (loc.startsWith('/gifts')) return 1;
      if (loc.startsWith('/events')) return 2;
      if (loc.startsWith('/projects')) return 3;
      if (loc.startsWith('/profile')) return 4;
    } else {
      if (loc.startsWith('/events')) return 1;
      if (loc.startsWith('/projects')) return 2;
      if (loc.startsWith('/profile')) return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isB2B = user?.clientType == ClientType.b2b; // Direct check to avoid getter errors

    final idx = _selectedIndex(context, isB2B);
    
    const b2bRoutes = ['/home', '/gifts', '/events', '/projects', '/profile'];
    const b2cRoutes = ['/home', '/events', '/projects', '/profile'];
    final routes = isB2B ? b2bRoutes : b2cRoutes;

    const b2bItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Accueil',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.card_giftcard_outlined),
        activeIcon: Icon(Icons.card_giftcard),
        label: 'Cadeaux',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.event_outlined),
        activeIcon: Icon(Icons.event),
        label: 'Événements',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_outlined),
        activeIcon: Icon(Icons.inventory_2),
        label: 'Projets',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];

    const b2cItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Accueil',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.event_outlined),
        activeIcon: Icon(Icons.event),
        label: 'Événements',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_outlined),
        activeIcon: Icon(Icons.inventory_2),
        label: 'Projets',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) => context.go(routes[i]),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.navyBlue,
          unselectedItemColor: AppColors.textHint,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: isB2B ? b2bItems : b2cItems,
        ),
      ),
    );
  }
}
