class WalletModel {
  final String address;
  final String privateKey;
  final String name;
  final DateTime createdAt;
  final double? balance;

  WalletModel({
    required this.address,
    required this.privateKey,
    required this.name,
    required this.createdAt,
    this.balance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      address: json['address'] as String,
      privateKey: json['privateKey'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      balance: json['balance'] != null ? (json['balance'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'privateKey': privateKey,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'balance': balance,
    };
  }
}