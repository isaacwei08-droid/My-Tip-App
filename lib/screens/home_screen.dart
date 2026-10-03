import 'package:flutter/material.dart';
import 'community_screen.dart';
import 'dashboard_screen.dart';
import 'receipt_history_screen.dart';
import 'scanner_screen.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CommunityScreen(),
    const DashboardScreen(),
    const AIChatScreen(),
    const ReceiptHistoryScreen(),
    const ScannerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFECEFF1),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.blueGrey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded), label: "Community"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_rounded), label: "AI Chat"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded), label: "History"),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded), label: "Scan"),
        ],
      ),
    );
  }
}
