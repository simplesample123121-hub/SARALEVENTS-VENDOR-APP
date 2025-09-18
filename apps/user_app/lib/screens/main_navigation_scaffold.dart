import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'planning_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';
import '../widgets/wishlist_manager.dart';
import '../core/wishlist_notifier.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeScreen(),
    OrdersScreen(),
    PlanningScreen(),
    WishlistScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return WishlistManager(
      child: Scaffold(
        appBar: null,
        body: _tabs[_currentIndex],
        bottomNavigationBar: ListenableBuilder(
          listenable: WishlistNotifier.instance,
          builder: (context, _) {
            final wishlistCount = WishlistNotifier.instance.count;
            
            return BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
              selectedItemColor: const Color(0xFFFDBB42),
              unselectedItemColor: Colors.grey.shade600,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  activeIcon: Icon(Icons.home, color: Color(0xFFFDBB42)),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  activeIcon: Icon(Icons.receipt_long, color: Color(0xFFFDBB42)),
                  label: 'Orders',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.event_note),
                  activeIcon: Icon(Icons.event_note, color: Color(0xFFFDBB42)),
                  label: 'Planning',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.favorite_border),
                      if (wishlistCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              wishlistCount > 99 ? '99+' : wishlistCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: Stack(
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFFFDBB42)),
                      if (wishlistCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              wishlistCount > 99 ? '99+' : wishlistCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Wishlist',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  activeIcon: Icon(Icons.person, color: Color(0xFFFDBB42)),
                  label: 'Profile',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
