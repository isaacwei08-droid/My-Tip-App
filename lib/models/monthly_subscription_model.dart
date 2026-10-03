class MonthlySubscriptionModel {
  final String id;
  final String name;
  final double amount;

  const MonthlySubscriptionModel({
    required this.id,
    required this.name,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
    };
  }

  factory MonthlySubscriptionModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return MonthlySubscriptionModel(
      id: id,
      name: data['name'] as String? ?? 'Subscription',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
