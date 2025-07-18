// admin_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:sakubijak/screens/admin/admin_audit_log.dart';
import 'package:sakubijak/screens/admin/admin_categories.dart';
import 'package:sakubijak/screens/admin/admin_dashboard.dart';
import 'package:sakubijak/screens/admin/admin_setting_screen.dart';
import 'package:sakubijak/screens/admin/admin_users.dart';

class AdminNavigationScreen extends StatefulWidget {
  @override
  _AdminNavigationScreenState createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminCategoriesScreen(),
    SimpleAuditLogTest(),
    AdminSettingsScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
    BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Kategori'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Log'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF00BFA5),
        unselectedItemColor: Colors.grey,
        items: _navItems,
      ),
    );
  }
}
