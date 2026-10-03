import 'package:flutter/material.dart';
import 'package:example_app_2/screens/dashboard_screen.dart';
import 'package:example_app_2/screens/community_screen.dart';
import 'package:example_app_2/screens/scanner_screen.dart';
import 'package:example_app_2/screens/ai_chat_screen.dart'; // Import the AI Chat screen
import 'package:example_app_2/screens/receipt_history_screen.dart'; // Import the History screen
import 'package:example_app_2/widgets/dashboard_navigation_scope.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  // List of the main screens
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    CommunityScreen(),
    AIChatScreen(), // Fixed the class name to AIChatScreen
    ReceiptHistoryScreen(),
    ScannerScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardNavigationScope(
      goToDashboard: () => _onItemTapped(0),
      child: Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFECEFF1),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_rounded),
              label: 'AI Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              label: 'Scanner',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.blueGrey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
