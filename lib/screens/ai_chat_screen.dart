import 'package:flutter/material.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../widgets/draggable_scrollbar.dart';
import '../widgets/app_logo.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  String _aiResponse = "Select a receipt from history to analyze the tip.";
  bool _isLoading = false;
  ReceiptModel? _selectedReceipt;
  final ScrollController _analysisScrollController = ScrollController();

  @override
  void dispose() {
    _analysisScrollController.dispose();
    super.dispose();
  }

  void _analyzeReceipt(ReceiptModel receipt) async {
    setState(() {
      _isLoading = true;
      _selectedReceipt = receipt;
      _aiResponse = "Analyzing tip for ${receipt.merchant}...";
    });

    final response = await AIService.checkTip(receipt.subtotal, receipt.tip);

    setState(() {
      _aiResponse = response;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 68,
        leading: const AppLogo(),
        title: const Text("AI Tip Assistant"),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                fontFamily: 'sans-serif',
                bodyColor: Colors.black87,
                displayColor: Colors.black87,
              ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF8FFF9),
                Colors.green.shade50,
                Colors.green.shade100,
              ],
              stops: const [0.0, 0.52, 1.0],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Scrollbar(
                    controller: _analysisScrollController,
                    thumbVisibility: true,
                    interactive: true,
                    radius: const Radius.circular(8),
                    child: SingleChildScrollView(
                      controller: _analysisScrollController,
                      child: Card(
                        elevation: 4,
                        color: Colors.amber.shade50,
                        shadowColor: Colors.amber.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: Colors.amber.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.green.shade700,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade800,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'AI Analysis',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_isLoading)
                                const Center(child: CircularProgressIndicator())
                              else
                                Text(
                                  _aiResponse,
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              if (!_isLoading && _selectedReceipt != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _selectedReceipt!.tipPercentage == null
                                        ? 'Tip basis: Not recorded for this receipt.'
                                        : 'Tip basis: ${_selectedReceipt!.tipPercentage!.toStringAsFixed(1)}% '
                                            '${_selectedReceipt!.tipBasis == 'afterTax' ? 'after tax' : 'before tax'}.',
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Select a receipt to check tip:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: StreamBuilder<List<ReceiptModel>>(
                  stream: FirestoreService.getReceipts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final receipts = snapshot.data ?? [];
                    if (receipts.isEmpty) {
                      return const Center(child: Text("No receipts found."));
                    }

                    return DraggableScrollbar(
                      builder: (context, scrollController) =>
                          ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.only(right: 8),
                        itemCount: receipts.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          endIndent: 12,
                          color: Colors.green.shade300,
                        ),
                        itemBuilder: (context, index) {
                          final receipt = receipts[index];
                          return ListTile(
                            title: Text(
                              receipt.merchant,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              "Subtotal: \$${receipt.subtotal.toStringAsFixed(2)} | Tip: \$${receipt.tip.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.receipt_long_rounded,
                              size: 34,
                              color: Colors.green,
                            ),
                            onTap: () => _analyzeReceipt(receipt),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
