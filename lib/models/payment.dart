class Payment {
  final String id;
  final String appointmentId;
  final double amount;
  final String currency;
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String paymentMethod; // 'card', 'paypal', etc.
  final DateTime createdAt;
  final String? transactionId;
  final double platformCommission; // Platform's commission (15%)
  final double providerAmount; // Amount provider receives (85%)
  final double commissionRate; // Commission rate percentage

  Payment({
    required this.id,
    required this.appointmentId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.transactionId,
    this.platformCommission = 0,
    this.providerAmount = 0,
    this.commissionRate = 15.0,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'card',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      transactionId: json['transactionId'],
      platformCommission: (json['platformCommission'] ?? 0).toDouble(),
      providerAmount: (json['providerAmount'] ?? 0).toDouble(),
      commissionRate: (json['commissionRate'] ?? 15.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'transactionId': transactionId,
      'platformCommission': platformCommission,
      'providerAmount': providerAmount,
      'commissionRate': commissionRate,
    };
  }
}
