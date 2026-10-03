class ReceiptModel {
  final String id;
  final String merchant;
  final double subtotal;
  final double tax;
  final double tip;
  final double total;
  final String imageUrl;
  final String city;
  final double? tipPercentage;
  final String tipBasis;

  ReceiptModel({
    required this.id,
    required String merchant,
    required this.subtotal,
    required this.tax,
    required this.tip,
    required this.total,
    required this.imageUrl,
    this.city = '',
    this.tipPercentage,
    this.tipBasis = 'beforeTax',
  }) : merchant = _capitalizeFirstLetter(merchant);

  static String _capitalizeFirstLetter(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) return trimmedValue;
    return '${trimmedValue[0].toUpperCase()}${trimmedValue.substring(1)}';
  }

  Map<String, dynamic> toMap() {
    return {
      "merchant": merchant,
      "subtotal": subtotal,
      "tax": tax,
      "tip": tip,
      "total": total,
      "imageUrl": imageUrl,
      "city": city,
      "tipPercentage": tipPercentage,
      "tipBasis": tipBasis,
    };
  }

  factory ReceiptModel.fromMap(String id, Map<String, dynamic> data) {
    return ReceiptModel(
      id: id,
      merchant: data["merchant"],
      subtotal: data["subtotal"],
      tax: data["tax"],
      tip: data["tip"],
      total: data["total"],
      imageUrl: data["imageUrl"],
      city: data["city"] as String? ?? '',
      tipPercentage: (data["tipPercentage"] as num?)?.toDouble(),
      tipBasis: data["tipBasis"] as String? ?? 'beforeTax',
    );
  }
}
