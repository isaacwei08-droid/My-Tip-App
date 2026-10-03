import 'package:flutter/material.dart';
import 'dashboard_navigation_scope.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Go to Dashboard',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: DashboardNavigationScope.maybeOf(context)?.goToDashboard,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/tipsense_logo.png',
              fit: BoxFit.cover,
              semanticLabel: 'TipSense logo',
            ),
          ),
        ),
      ),
    );
  }
}
