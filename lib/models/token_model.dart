class TokenModel {
  final String address;
  final String symbol;
  final String name;
  final int decimals;
  final String balance;
  final bool isNative;

  TokenModel({
    required this.address,
    required this.symbol,
    required this.name,
    required this.decimals,
    required this.balance,
    this.isNative = false,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      address: json['address'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      decimals: json['decimals'] as int,
      balance: json['balance'] as String,
      isNative: json['isNative'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'symbol': symbol,
      'name': name,
      'decimals': decimals,
      'balance': balance,
      'isNative': isNative,
    };
  }

  static TokenModel nativeEth(String balance) {
    return TokenModel(
      address: '0x0000000000000000000000000000000000000000',
      symbol: 'SepoliaETH',
      name: 'Sepolia',
      decimals: 18,
      balance: balance,
      isNative: true,
    );
  }
}