class DriverWallet {
  final double balance;
  final String currency;
  final String status;
  final double monthlyEarnings;

  const DriverWallet({
    required this.balance,
    required this.currency,
    required this.status,
    required this.monthlyEarnings,
  });

  factory DriverWallet.fromJson(Map<String, dynamic> json) {
    return DriverWallet(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'MAD',
      status: json['status'] as String? ?? 'UNKNOWN',
      monthlyEarnings: (json['monthlyEarnings'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WalletTransaction {
  final String id;
  final double amount;
  final String direction;
  final String reason;
  final String? description;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.direction,
    required this.reason,
    this.description,
    required this.createdAt,
  });

  bool get isCredit => direction == 'CREDIT';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    DateTime parsedCreatedAt;

    if (createdAt is String) {
      parsedCreatedAt = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else if (createdAt is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(createdAt);
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return WalletTransaction(
      id: json['id'].toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      direction: json['direction']?.toString() ?? 'UNKNOWN',
      reason: json['reason']?.toString() ?? 'UNKNOWN',
      description: json['description'] as String?,
      createdAt: parsedCreatedAt,
    );
  }
}
