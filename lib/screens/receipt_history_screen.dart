import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';
import '../widgets/draggable_scrollbar.dart';
import '../widgets/app_logo.dart';

class ReceiptHistoryScreen extends StatelessWidget {
  const ReceiptHistoryScreen({super.key});

  void _showAddReceiptDialog(BuildContext screenContext) {
    final merchantController = TextEditingController();
    final cityController = TextEditingController();
    final subtotalController = TextEditingController();
    final taxController = TextEditingController();
    final tipController = TextEditingController();
    final totalController = TextEditingController();

    const double californiaTaxRate = 0.0725; // 7.25%

    double taxRateForCity(String city) {
      switch (city.trim().toLowerCase()) {
        case 'los angeles':
          return 0.095;
        case 'san francisco':
          return 0.08625;
        case 'san diego':
          return 0.0775;
        case 'san jose':
          return 0.0925;
        case 'oakland':
          return 0.1025;
        case 'sacramento':
          return 0.0875;
        default:
          return californiaTaxRate;
      }
    }

    void calculateTaxAndTotal() {
      final subtotal = double.tryParse(subtotalController.text) ?? 0.0;

      final taxRate = taxRateForCity(cityController.text);
      final calculatedTax = subtotal * taxRate;
      taxController.text =
          calculatedTax > 0 ? calculatedTax.toStringAsFixed(2) : "";

      final tip = double.tryParse(tipController.text) ?? 0.0;
      final total = subtotal + calculatedTax + tip;

      // Update the total field
      totalController.text = total > 0 ? total.toStringAsFixed(2) : "";
    }

    void calculateTotalOnly() {
      final subtotal = double.tryParse(subtotalController.text) ?? 0.0;
      final tax = double.tryParse(taxController.text) ?? 0.0;
      final tip = double.tryParse(tipController.text) ?? 0.0;
      final total = subtotal + tax + tip;

      totalController.text = total > 0 ? total.toStringAsFixed(2) : "";
    }

    const tipPercentages = [15, 18, 20, 25];

    showDialog(
      context: screenContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add New Receipt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: merchantController,
                  decoration: const InputDecoration(labelText: 'Merchant Name'),
                ),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    labelText: 'City (optional)',
                    hintText: 'Used to estimate local sales tax',
                  ),
                  onChanged: (_) {
                    calculateTaxAndTotal();
                    setDialogState(() {});
                  },
                ),
                TextField(
                  controller: subtotalController,
                  decoration: const InputDecoration(labelText: 'Subtotal'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    calculateTaxAndTotal();
                    setDialogState(() {});
                  },
                ),
                TextField(
                  controller: taxController,
                  decoration: const InputDecoration(labelText: 'Tax'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    calculateTotalOnly();
                    setDialogState(() {});
                  },
                ),
                TextField(
                  controller: tipController,
                  decoration: const InputDecoration(labelText: 'Tip'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    calculateTotalOnly();
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Common tip preview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ...tipPercentages.map((percentage) {
                  final subtotal =
                      double.tryParse(subtotalController.text) ?? 0;
                  final tax = double.tryParse(taxController.text) ?? 0;
                  final expectedTip = subtotal * percentage / 100;
                  final expectedTotal = subtotal + tax + expectedTip;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$percentage% tip: \$${expectedTip.toStringAsFixed(2)}  •  '
                      'total: \$${expectedTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }),
                TextField(
                  controller: totalController,
                  decoration: const InputDecoration(labelText: 'Total Amount'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                FocusScope.of(dialogContext).unfocus();
                final merchant = merchantController.text;
                final city = cityController.text.trim();
                final subtotal =
                    double.tryParse(subtotalController.text) ?? 0.0;
                final tax = double.tryParse(taxController.text) ?? 0.0;
                final tip = double.tryParse(tipController.text) ?? 0.0;
                final total = double.tryParse(totalController.text) ?? 0.0;

                if (merchant.isNotEmpty && total > 0) {
                  final newReceipt = ReceiptModel(
                    id: '',
                    merchant: merchant,
                    subtotal: subtotal,
                    tax: tax,
                    tip: tip,
                    total: total,
                    imageUrl: '',
                    city: city,
                  );
                  Navigator.pop(dialogContext);
                  try {
                    await FirestoreService.addReceipt(newReceipt);
                    if (screenContext.mounted) {
                      ScaffoldMessenger.of(screenContext).showSnackBar(
                        const SnackBar(content: Text('Receipt added!')),
                      );
                    }
                  } catch (_) {
                    if (screenContext.mounted) {
                      ScaffoldMessenger.of(screenContext).showSnackBar(
                        const SnackBar(content: Text('Could not add receipt.')),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReceiptDialog(
    BuildContext screenContext,
    ReceiptModel receipt,
  ) {
    final merchantController = TextEditingController(text: receipt.merchant);
    final cityController = TextEditingController(text: receipt.city);
    final subtotalController =
        TextEditingController(text: receipt.subtotal.toStringAsFixed(2));
    final taxController =
        TextEditingController(text: receipt.tax.toStringAsFixed(2));
    final tipController =
        TextEditingController(text: receipt.tip.toStringAsFixed(2));
    String tipBasis = receipt.tipBasis;
    final tipPercentageController = TextEditingController(
      text: (receipt.tipPercentage ??
              (receipt.subtotal +
                          (receipt.tipBasis == 'afterTax' ? receipt.tax : 0) >
                      0
                  ? receipt.tip /
                      (receipt.subtotal +
                          (receipt.tipBasis == 'afterTax' ? receipt.tax : 0)) *
                      100
                  : 0))
          .toStringAsFixed(1),
    );
    final totalController =
        TextEditingController(text: receipt.total.toStringAsFixed(2));

    void calculateFromPercentage() {
      final subtotal = double.tryParse(subtotalController.text) ?? 0;
      final tax = double.tryParse(taxController.text) ?? 0;
      final percentage = double.tryParse(tipPercentageController.text) ?? 0;
      final tipBase = tipBasis == 'afterTax' ? subtotal + tax : subtotal;
      final tip = tipBase * percentage / 100;
      tipController.text = tip.toStringAsFixed(2);
      totalController.text = (subtotal + tax + tip).toStringAsFixed(2);
    }

    void calculateFromTip() {
      final subtotal = double.tryParse(subtotalController.text) ?? 0;
      final tax = double.tryParse(taxController.text) ?? 0;
      final tip = double.tryParse(tipController.text) ?? 0;
      final tipBase = tipBasis == 'afterTax' ? subtotal + tax : subtotal;
      final percentage = tipBase > 0 ? tip / tipBase * 100 : 0;
      tipPercentageController.text = percentage.toStringAsFixed(1);
      totalController.text = (subtotal + tax + tip).toStringAsFixed(2);
    }

    showDialog(
      context: screenContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Receipt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: merchantController,
                  decoration: const InputDecoration(labelText: 'Merchant Name'),
                ),
                TextField(
                  controller: cityController,
                  decoration:
                      const InputDecoration(labelText: 'City (optional)'),
                ),
                TextField(
                  controller: subtotalController,
                  decoration: const InputDecoration(labelText: 'Subtotal'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    calculateFromPercentage();
                    setDialogState(() {});
                  },
                ),
                TextField(
                  controller: taxController,
                  decoration: const InputDecoration(labelText: 'Tax'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    calculateFromPercentage();
                    setDialogState(() {});
                  },
                ),
                TextField(
                  controller: tipController,
                  decoration: const InputDecoration(labelText: 'Tip amount'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    calculateFromTip();
                    setDialogState(() {});
                  },
                ),
                TextField(
                  controller: tipPercentageController,
                  decoration: const InputDecoration(
                    labelText: 'Tip percentage',
                    suffixText: '%',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {
                    calculateFromPercentage();
                    setDialogState(() {});
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: tipBasis,
                  decoration: const InputDecoration(
                    labelText: 'Tip calculated',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'beforeTax',
                      child: Text('Before tax'),
                    ),
                    DropdownMenuItem(
                      value: 'afterTax',
                      child: Text('After tax'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    tipBasis = value;
                    calculateFromPercentage();
                    setDialogState(() {});
                  },
                ),
                TextField(
                  controller: totalController,
                  decoration: const InputDecoration(labelText: 'Total Amount'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                FocusScope.of(dialogContext).unfocus();
                final merchant = merchantController.text.trim();
                final subtotal = double.tryParse(subtotalController.text) ?? 0;
                final tax = double.tryParse(taxController.text) ?? 0;
                final tip = double.tryParse(tipController.text) ?? 0;
                final total = double.tryParse(totalController.text) ?? 0;
                if (merchant.isEmpty || total <= 0) return;

                final updatedReceipt = ReceiptModel(
                  id: receipt.id,
                  merchant: merchant,
                  subtotal: subtotal,
                  tax: tax,
                  tip: tip,
                  total: total,
                  imageUrl: receipt.imageUrl,
                  city: cityController.text.trim(),
                  tipPercentage: double.tryParse(tipPercentageController.text),
                  tipBasis: tipBasis,
                );
                Navigator.pop(dialogContext);
                try {
                  await FirestoreService.updateReceipt(updatedReceipt);
                  if (screenContext.mounted) {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      const SnackBar(content: Text('Receipt updated!')),
                    );
                  }
                } catch (_) {
                  if (screenContext.mounted) {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      const SnackBar(
                          content: Text('Could not update receipt.')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTipGuideDialog(BuildContext screenContext) {
    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.percent_rounded, color: Color(0xFFE65100)),
            SizedBox(width: 8),
            Text('Common Tip Percentages'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Text('15%', style: TextStyle(fontWeight: FontWeight.bold)),
              title: Text('Good service'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Text('18%', style: TextStyle(fontWeight: FontWeight.bold)),
              title: Text('Very good service'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Text('20%', style: TextStyle(fontWeight: FontWeight.bold)),
              title: Text('Excellent service'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Text('25%', style: TextStyle(fontWeight: FontWeight.bold)),
              title: Text('Exceptional service'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReceiptPreviewDialog(
    BuildContext screenContext,
    ReceiptModel receipt,
  ) {
    final tipPercentages = [15, 18, 20, 25];

    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(receipt.merchant),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Subtotal: \$${receipt.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Tax: \$${receipt.tax.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Saved tip: \$${receipt.tip.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Saved total: \$${receipt.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Common tip options',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 4),
              ...tipPercentages.map((percentage) {
                final tip = receipt.subtotal * percentage / 100;
                final projectedTotal = receipt.subtotal + receipt.tax + tip;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Text(
                    '$percentage%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: Text('Tip: \$${tip.toStringAsFixed(2)}'),
                  trailing: Text(
                    'Total \$${projectedTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        leadingWidth: 68,
        leading: const AppLogo(),
        title: const Text('Receipt History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.percent_rounded),
            tooltip: 'View common tip percentages',
            onPressed: () => _showTipGuideDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<ReceiptModel>>(
        stream: FirestoreService.getReceipts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final receipts = snapshot.data ?? [];

          if (receipts.isEmpty) {
            return const Center(child: Text('No receipts found.'));
          }

          return DraggableScrollbar(
            builder: (context, scrollController) => ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.only(right: 8),
              itemCount: receipts.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                indent: 58,
                endIndent: 12,
                color: Colors.deepOrange.shade200,
              ),
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                final tipPercentage = receipt.subtotal > 0
                    ? (receipt.tip / receipt.subtotal * 100)
                    : null;
                return ListTile(
                  leading: const Icon(
                    Icons.receipt_long_rounded,
                    size: 34,
                    color: Color(0xFFE65100),
                  ),
                  title: Text(
                    receipt.merchant,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Colors.deepOrange.shade900,
                    ),
                  ),
                  subtitle: Text(
                    'Total: \$${receipt.total.toStringAsFixed(2)}  •  Tip: \$${receipt.tip.toStringAsFixed(2)}'
                    '${tipPercentage == null ? '' : ' (${tipPercentage.toStringAsFixed(1)}%)'}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: 'Edit receipt',
                        onPressed: () =>
                            _showEditReceiptDialog(context, receipt),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 30,
                        ),
                        tooltip: 'Delete receipt',
                        onPressed: () =>
                            FirestoreService.deleteReceipt(receipt.id),
                      ),
                    ],
                  ),
                  onTap: () => _showReceiptPreviewDialog(context, receipt),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReceiptDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
