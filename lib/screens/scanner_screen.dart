import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/receipt_model.dart';
import '../services/firestore_service.dart';
import '../widgets/app_logo.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  Future<void> scanReceipt(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      try {
        // Show loading indicator
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
        }

        // OCR Processing
        final inputImage = InputImage.fromFilePath(image.path);
        final textRecognizer =
            TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        final extractedData = _parseReceiptText(recognizedText.text);
        textRecognizer.close();

        final newReceipt = ReceiptModel(
          id: '', // Firestore will generate this
          merchant: extractedData['merchant'] ?? "Unknown Store",
          subtotal: extractedData['subtotal'] ?? 0.0,
          tax: extractedData['tax'] ?? 0.0,
          tip: extractedData['tip'] ?? 0.0,
          total: extractedData['total'] ?? 0.0,
          // The camera image is processed locally and is not uploaded.
          imageUrl: '',
        );

        await FirestoreService.addReceipt(newReceipt);

        if (context.mounted) {
          Navigator.pop(context); // Remove loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Receipt saved: ${newReceipt.merchant} - Total: \$${newReceipt.total}',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Remove loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving receipt: $e')),
          );
        }
      }
    }
  }

  Map<String, dynamic> _parseReceiptText(String text) {
    final lines = text.split('\n');
    String merchant = "Unknown Store";
    double subtotal = 0.0;
    double tax = 0.0;
    double tip = 0.0;
    double total = 0.0;

    final merchantLinePattern = RegExp(
      r'(cashier|server|employee|associate|customer|order|receipt|'
      r'subtotal|total|tax|tip|date|time|phone|tel|address|street|'
      r'avenue|ave\b|road|rd\b|boulevard|blvd\b|www\.|https?://|@)',
      caseSensitive: false,
    );
    final moneyOrNumberPattern = RegExp(r'(\$\s*\d|\d{4,})');

    for (final line in lines.take(10)) {
      final candidate = line.trim();
      if (candidate.length < 3 ||
          merchantLinePattern.hasMatch(candidate) ||
          moneyOrNumberPattern.hasMatch(candidate)) {
        continue;
      }
      merchant = candidate;
      break;
    }

    final totalRegex = RegExp(
      r'(grand\s+total|total\s+due|amount\s+due|balance\s+due|total)',
      caseSensitive: false,
    );
    final subtotalRegex = RegExp(
      r'(subtotal|sub\s+total|net)',
      caseSensitive: false,
    );
    final taxRegex = RegExp(r'(tax|vat|gst)', caseSensitive: false);
    final tipRegex = RegExp(r'(tip|gratuity)', caseSensitive: false);
    final amountRegex = RegExp(r'\$?\s*\d{1,7}(?:[,.]\d{2}|\s+\d{2})?');
    final allAmounts = <double>[];
    final decimalAmounts = <double>[];

    double? parseAmount(String rawAmount) {
      final raw = rawAmount.replaceAll('\$', '').trim();
      final spacedParts = raw.split(RegExp(r'\s+'));
      final normalized = spacedParts.length == 2 && spacedParts.last.length == 2
          ? '${spacedParts.first}.${spacedParts.last}'
          : raw.replaceAll(',', '.');
      return double.tryParse(normalized);
    }

    double? amountAfterLabel(RegExp labelRegex, String line) {
      final labelMatch = labelRegex.firstMatch(line);
      if (labelMatch == null) return null;
      final amountMatch =
          amountRegex.firstMatch(line.substring(labelMatch.end));
      if (amountMatch == null) return null;
      return parseAmount(amountMatch.group(0)!);
    }

    for (var line in lines) {
      final hasAmountLabel = totalRegex.hasMatch(line) ||
          subtotalRegex.hasMatch(line) ||
          taxRegex.hasMatch(line) ||
          tipRegex.hasMatch(line);
      final hasCurrencySymbol = line.contains('\$');
      final isPostalCodeLine = RegExp(r'\b\d{5}(?:-\d{4})?\b').hasMatch(line);
      final isPhoneLine =
          RegExp(r'\b\d{3}[-. ]\d{3}[-. ]\d{4}\b').hasMatch(line);
      final isCardLine = RegExp(
        r'(card|visa|mastercard|amex|debit|credit|ending|last\s*4|xxxx|\*{2,})',
        caseSensitive: false,
      ).hasMatch(line);

      // Address and phone lines frequently contain the largest numbers on a
      // receipt, but they are not prices.
      if ((isPostalCodeLine || isPhoneLine || isCardLine) &&
          !hasAmountLabel &&
          !hasCurrencySymbol) {
        continue;
      }

      for (final match in amountRegex.allMatches(line)) {
        final rawAmount = match.group(0)!;
        final plainFourDigitNumber =
            RegExp(r'^\s*\d{4}\s*$').hasMatch(rawAmount);
        if (plainFourDigitNumber && !hasAmountLabel && !hasCurrencySymbol) {
          continue;
        }
        final value = parseAmount(rawAmount);
        if (value != null && value > 0) {
          allAmounts.add(value);
          if (RegExp(r'[,.]\d{2}|\s+\d{2}').hasMatch(rawAmount)) {
            decimalAmounts.add(value);
          }
        }
      }

      total =
          total == 0.0 ? amountAfterLabel(totalRegex, line) ?? total : total;
      subtotal = subtotal == 0.0
          ? amountAfterLabel(subtotalRegex, line) ?? subtotal
          : subtotal;
      tax = tax == 0.0 ? amountAfterLabel(taxRegex, line) ?? tax : tax;
      tip = tip == 0.0 ? amountAfterLabel(tipRegex, line) ?? tip : tip;
    }

    if (total == 0.0 && decimalAmounts.isNotEmpty) {
      // Receipt totals are normally the final currency value printed.
      total = decimalAmounts.last;
    } else if (total == 0.0 && allAmounts.isNotEmpty) {
      // Ignore likely ZIP codes, phone numbers, and other large integers.
      final plausibleIntegers = allAmounts.where((value) => value <= 10000);
      if (plausibleIntegers.isNotEmpty) {
        total = plausibleIntegers.last;
      }
    }

    if (total == 0.0 && subtotal != 0.0) {
      total = subtotal + tax + tip;
    }

    return {
      'merchant': merchant,
      'subtotal': subtotal,
      'tax': tax,
      'tip': tip,
      'total': total,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 68,
        leading: const AppLogo(),
        title: const Text("Receipt Scanner"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => scanReceipt(context),
          child: const Text("Scan Receipt"),
        ),
      ),
    );
  }
}
