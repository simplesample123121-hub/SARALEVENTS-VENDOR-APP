import 'package:flutter/material.dart';
import '../../core/ui/app_icons.dart';
import '../dashboard/dashboard_screen.dart';
import '../orders/orders_screen.dart';
import '../chat/chat_screen.dart';
import '../services/services_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DashboardScreen(),
    OrdersScreen(),
    ChatScreen(),
    ServicesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: SvgIcon(AppIcons.homeLineSvg, size: 22),
            activeIcon: SvgIcon(AppIcons.homeSolidSvg, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SvgIcon(AppIcons.ordersLineSvg, size: 22),
            activeIcon: SvgIcon(AppIcons.ordersSolidSvg, size: 22),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: SvgIcon(AppIcons.chatLineSvg, size: 22),
            activeIcon: SvgIcon(AppIcons.chatSolidSvg, size: 22),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: SvgIcon(AppIcons.catalogLineSvg, size: 22),
            activeIcon: SvgIcon(AppIcons.catalogSolidSvg, size: 20),
            label: 'Catalog',
          ),
          BottomNavigationBarItem(
            icon: SvgIcon(AppIcons.vendorLineSvg, size: 22),
            activeIcon: SvgIcon(AppIcons.vendorSvg, size: 24, color: Theme.of(context).colorScheme.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}


