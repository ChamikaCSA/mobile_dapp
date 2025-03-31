class TokenModel {
  final String address;
  final String symbol;
  final String name;
  final int decimals;
  final String balance;

  TokenModel({
    required this.address,
    required this.symbol,
    required this.name,
    required this.decimals,
    required this.balance,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      address: json['address'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      decimals: json['decimals'] as int,
      balance: json['balance'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'symbol': symbol,
      'name': name,
      'decimals': decimals,
      'balance': balance,
    };
  }
}