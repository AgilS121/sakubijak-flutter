// main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:sakubijak/screens/TransaksiScreen.dart';
import 'package:sakubijak/screens/analisScreen.dart';
import 'package:sakubijak/screens/anggaranScreen.dart';
import 'package:sakubijak/screens/dashboardScreen.dart';
import 'package:sakubijak/screens/profileScreen.dart';
import 'package:sakubijak/screens/targetScreen.dart';
import 'package:sakubijak/utils/bottomBar.dart';

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(), // Dashboard di posisi pertama (index 0)
    AnalysisScreen(), // Analysis di posisi kedua (index 1)
    BudgetPage(), // Assuming this is the AnalisScreen
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
