import 'package:web3dart/web3dart.dart';
import 'dart:convert';
import '../models/token_model.dart';
import 'base_service.dart';

class TokenService extends BaseService {
  Future<TokenModel> getTokenInfo(String tokenAddress) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(
          json.encode([
            {
              "constant": true,
              "inputs": [],
              "name": "name",
              "outputs": [{"name": "", "type": "string"}],
              "payable": false,
              "stateMutability": "view",
              "type": "function"
            },
            {
              "constant": true,
              "inputs": [],
              "name": "symbol",
              "outputs": [{"name": "", "type": "string"}],
              "payable": false,
              "stateMutability": "view",
              "type": "function"
            },
            {
              "constant": true,
              "inputs": [],
              "name": "decimals",
              "outputs": [{"name": "", "type": "uint8"}],
              "payable": false,
              "stateMutability": "view",
              "type": "function"
            },
          ]),
          tokenAddress,
        ),
        EthereumAddress.fromHex(tokenAddress),
      );

      final nameFunction = contract.function('name');
      final symbolFunction = contract.function('symbol');
      final decimalsFunction = contract.function('decimals');

      final name = await web3client.call(
        contract: contract,
        function: nameFunction,
        params: [],
      );
      final symbol = await web3client.call(
        contract: contract,
        function: symbolFunction,
        params: [],
      );
      final decimals = await web3client.call(
        contract: contract,
        function: decimalsFunction,
        params: [],
      );

      return TokenModel(
        address: tokenAddress,
        name: name.first.toString(),
        symbol: symbol.first.toString(),
        decimals: (decimals.first as BigInt).toInt(),
        balance: '0',
      );
    } catch (e) {
      throw Exception('Failed to get token info: $e');
    }
  }

  Future<String> getTokenBalance(String tokenAddress, String walletAddress) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(
          json.encode([
            {
              "constant": true,
              "inputs": [{"name": "_owner", "type": "address"}],
              "name": "balanceOf",
              "outputs": [{"name": "balance", "type": "uint256"}],
              "payable": false,
              "stateMutability": "view",
              "type": "function"
            }
          ]),
          tokenAddress,
        ),
        EthereumAddress.fromHex(tokenAddress),
      );

      final balanceFunction = contract.function('balanceOf');
      final balance = await web3client.call(
        contract: contract,
        function: balanceFunction,
        params: [EthereumAddress.fromHex(walletAddress)],
      );

      return (balance.first as BigInt).toString();
    } catch (e) {
      throw Exception('Failed to get token balance: $e');
    }
  }
}