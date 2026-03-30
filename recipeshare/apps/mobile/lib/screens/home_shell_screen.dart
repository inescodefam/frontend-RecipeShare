import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:shared/shared.dart';

/// Wraps authenticated app routes with bottom navigation.
///
/// Note: recipe detail routes live outside this shell so they stay full screen.
class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  int get _selectedIndex {
    // location examples: /home/feed, /home/explore, /home/profile
    if (location.startsWith('/home/explore')) return 1;
    if (location.startsWith('/home/profile')) return 2;
    return 0; // /home/feed (default)
  }

  @override
  Widget build(BuildContext context) {
    final index = _selectedIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home/feed');
              break;
            case 1:
              context.go('/home/explore');
              break;
            case 2:
              context.go('/home/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

