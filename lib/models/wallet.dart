class Wallet {
  final String id;
  final String userId;
  final String type; // e.g., 'Vodafone Cash', 'Binance'
  final String iconClass;
  final String colorStart;
  final String colorEnd;
  final String details; // e.g., phone number or wallet address
  final double balance; // optional

  Wallet({
    required this.id,
    required this.userId,
    required this.type,
    required this.iconClass,
    required this.colorStart,
    required this.colorEnd,
    required this.details,
    this.balance = 0.0,
  });

  factory Wallet.fromMap(Map<String, dynamic> data, String documentId) {
    return Wallet(
      id: documentId,
      userId: data['user_id'] ?? '',
      type: data['type'] ?? '',
      iconClass: data['icon_class'] ?? 'fa-solid fa-wallet',
      colorStart: data['color_start'] ?? '#000000',
      colorEnd: data['color_end'] ?? '#333333',
      details: data['details'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'icon_class': iconClass,
      'color_start': colorStart,
      'color_end': colorEnd,
      'details': details,
      'balance': balance,
    };
  }
}
