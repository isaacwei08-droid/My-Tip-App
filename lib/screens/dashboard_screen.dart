import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/receipt_model.dart';
import '../models/monthly_subscription_model.dart';
import '../services/firestore_service.dart';
import '../widgets/draggable_scrollbar.dart';
import '../widgets/app_logo.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _showAddSubscriptionDialog(
    BuildContext context,
    String userId,
  ) async {
    var subscriptionName = '';
    var subscriptionAmount = '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Monthly Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) => subscriptionName = value,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Netflix',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => subscriptionAmount = value,
              decoration: const InputDecoration(
                labelText: 'Monthly amount',
                prefixText: r'$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              FocusScope.of(dialogContext).unfocus();
              final name = subscriptionName.trim();
              final amount = double.tryParse(subscriptionAmount.trim());
              if (name.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Enter a name and an amount greater than zero.'),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              try {
                await FirestoreService.addMonthlySubscription(
                  userId,
                  name,
                  amount,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subscription added!')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not add the subscription.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetDialog(
      BuildContext context, String userId, double currentBudget) {
    final budgetController =
        TextEditingController(text: currentBudget.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Monthly Budget'),
        content: TextField(
          controller: budgetController,
          decoration: const InputDecoration(labelText: 'Budget Amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              FocusScope.of(dialogContext).unfocus();
              final newBudget = double.tryParse(budgetController.text);
              if (newBudget != null && newBudget >= 0) {
                Navigator.pop(dialogContext);
                try {
                  await FirestoreService.updateBudget(userId, newBudget);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Budget updated!')),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not update budget.')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'default_user';

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        leadingWidth: 68,
        leading: const AppLogo(),
        title: const Text(
          "Spending Dashboard",
          style: TextStyle(fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: StreamBuilder<double>(
        stream: FirestoreService.getBudget(userId),
        builder: (context, budgetSnapshot) {
          final monthlyBudget = budgetSnapshot.data ?? 500.0;

          return StreamBuilder<List<ReceiptModel>>(
            stream: FirestoreService.getReceipts(),
            builder: (context, snapshot) {
              return StreamBuilder<List<MonthlySubscriptionModel>>(
                stream: FirestoreService.getMonthlySubscriptions(userId),
                builder: (context, subscriptionSnapshot) {
                  if ((snapshot.connectionState == ConnectionState.waiting ||
                          subscriptionSnapshot.connectionState ==
                              ConnectionState.waiting) &&
                      !budgetSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final receipts = snapshot.data ?? [];
                  final subscriptions = subscriptionSnapshot.data ?? [];
                  final receiptSpending =
                      receipts.fold<double>(0, (sum, item) => sum + item.total);
                  final subscriptionSpending = subscriptions.fold<double>(
                    0,
                    (sum, item) => sum + item.amount,
                  );
                  final totalSpending = receiptSpending + subscriptionSpending;
                  final remainingBudget = monthlyBudget - totalSpending;
                  final spendingPercentage = monthlyBudget > 0
                      ? (totalSpending / monthlyBudget * 100).clamp(0.0, 100.0)
                      : 100.0;

                  return DraggableScrollbar(
                    builder: (context, scrollController) =>
                        SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                      child: Column(
                        children: [
                          Card(
                            elevation: 4,
                            shadowColor:
                                Colors.deepPurple.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Monthly overview',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    totalSpending > monthlyBudget
                                        ? 'Your spending is over budget'
                                        : 'You are on track with your budget',
                                    style: TextStyle(
                                      color: totalSpending > monthlyBudget
                                          ? Colors.red.shade700
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 155,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        PieChart(
                                          PieChartData(
                                            centerSpaceRadius: 44,
                                            sectionsSpace: 3,
                                            startDegreeOffset: -90,
                                            sections: [
                                              PieChartSectionData(
                                                value: spendingPercentage,
                                                gradient: LinearGradient(
                                                  colors: totalSpending >
                                                          monthlyBudget
                                                      ? [
                                                          Colors
                                                              .orange.shade400,
                                                          Colors.red.shade600,
                                                        ]
                                                      : [
                                                          Colors.blue.shade400,
                                                          Colors.deepPurple,
                                                        ],
                                                ),
                                                showTitle: false,
                                                radius: 22,
                                              ),
                                              PieChartSectionData(
                                                value:
                                                    (100 - spendingPercentage)
                                                        .clamp(0.0, 100.0),
                                                color: Colors.blueGrey.shade100,
                                                showTitle: false,
                                                radius: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '\$${totalSpending.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              '${spendingPercentage.toStringAsFixed(0)}% of budget',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _ChartLegend(
                                        color: totalSpending > monthlyBudget
                                            ? Colors.red.shade500
                                            : Colors.deepPurple,
                                        label: 'Spent',
                                        value:
                                            '\$${totalSpending.toStringAsFixed(2)}',
                                      ),
                                      _ChartLegend(
                                        color: Colors.blueGrey.shade200,
                                        label: totalSpending > monthlyBudget
                                            ? 'Over by'
                                            : 'Remaining',
                                        value:
                                            '\$${remainingBudget.abs().toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DashboardOptionCard(
                            icon: Icons.account_balance_wallet_rounded,
                            color: Colors.deepPurple,
                            title: 'Monthly Budget',
                            subtitle: 'Your spending limit',
                            value: '\$${monthlyBudget.toStringAsFixed(2)}',
                            action: IconButton.filledTonal(
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Edit monthly budget',
                              onPressed: () => _showEditBudgetDialog(
                                context,
                                userId,
                                monthlyBudget,
                              ),
                            ),
                          ),
                          Card(
                            elevation: 2,
                            shadowColor: Colors.blue.withValues(alpha: 0.15),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              visualDensity: VisualDensity.compact,
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              leading: const _OptionIcon(
                                icon: Icons.autorenew_rounded,
                                color: Colors.blue,
                              ),
                              title: const Text(
                                'Monthly Subscriptions',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${subscriptions.length} recurring ${subscriptions.length == 1 ? 'expense' : 'expenses'}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              trailing: Text(
                                '\$${subscriptionSpending.toStringAsFixed(2)}/mo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blue,
                                ),
                              ),
                              children: [
                                if (subscriptions.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                                    child: Text(
                                        'No monthly subscriptions added yet.'),
                                  ),
                                ...subscriptions.map(
                                  (subscription) => ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    tileColor: Colors.blue.shade50,
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white,
                                      child: Text(
                                        subscription.name.characters.first
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(subscription.name),
                                    subtitle: Text(
                                      '\$${subscription.amount.toStringAsFixed(2)} per month',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Delete ${subscription.name}',
                                      onPressed: () => FirestoreService
                                          .deleteMonthlySubscription(
                                        userId,
                                        subscription.id,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 4),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.tonalIcon(
                                      onPressed: () =>
                                          _showAddSubscriptionDialog(
                                        context,
                                        userId,
                                      ),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add subscription'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _DashboardOptionCard(
                            icon: Icons.shopping_bag_rounded,
                            color: Colors.orange,
                            title: 'Total Spending',
                            subtitle: 'Receipts and subscriptions',
                            value: '\$${totalSpending.toStringAsFixed(2)}',
                            valueColor: totalSpending > monthlyBudget
                                ? Colors.red
                                : null,
                          ),
                          _DashboardOptionCard(
                            icon: remainingBudget >= 0
                                ? Icons.savings_rounded
                                : Icons.warning_amber_rounded,
                            color: remainingBudget >= 0
                                ? Colors.green
                                : Colors.red,
                            title: remainingBudget >= 0
                                ? 'Remaining Budget'
                                : 'Over Budget By',
                            subtitle: remainingBudget >= 0
                                ? 'Available to spend'
                                : 'Review your expenses',
                            value:
                                '\$${remainingBudget.abs().toStringAsFixed(2)}',
                            valueColor: remainingBudget >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _DashboardOptionCard extends StatelessWidget {
  const _DashboardOptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    this.valueColor,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String value;
  final Color? valueColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _OptionIcon(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 2),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionIcon extends StatelessWidget {
  const _OptionIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
