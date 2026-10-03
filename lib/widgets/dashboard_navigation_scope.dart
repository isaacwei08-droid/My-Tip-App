import 'package:flutter/widgets.dart';

class DashboardNavigationScope extends InheritedWidget {
  const DashboardNavigationScope({
    super.key,
    required this.goToDashboard,
    required super.child,
  });

  final VoidCallback goToDashboard;

  static DashboardNavigationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DashboardNavigationScope>();
  }

  @override
  bool updateShouldNotify(DashboardNavigationScope oldWidget) {
    return goToDashboard != oldWidget.goToDashboard;
  }
}
