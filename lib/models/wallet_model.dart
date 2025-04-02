class WalletModel {
  final String address;
  final String encryptedData;
  final String name;
  final DateTime createdAt;
  final double? balance;

  WalletModel({
    required this.address,
    required this.encryptedData,
    required this.name,
    required this.createdAt,
    this.balance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      address: json['address'] as String,
      encryptedData: json['encryptedData'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      balance: json['balance'] != null ? (json['balance'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'encryptedData': encryptedData,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'balance': balance,
    };
  }
}