import 'package:web3dart/web3dart.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/token_model.dart';
import 'base_service.dart';
import 'dart:math';

class TokenService extends BaseService {
  static const int _sepoliaChainId = 11155111;
  static const String _balanceFormat = '#,##0.0000';
  static const int _gasFeeDecimals = 6;
  static const int _gasPriceDecimals = 2;
  static const int _nativeTokenDecimals = 18;

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

      final tokenInfo = await getTokenInfo(tokenAddress);
      return formatTokenBalance(balance.first as BigInt, tokenInfo.decimals);
    } catch (e) {
      throw Exception('Failed to get token balance: $e');
    }
  }

  String formatTokenBalance(BigInt balance, int decimals) {
    final balanceInEther = balance / BigInt.from(10).pow(decimals);
    final double balanceDouble = double.parse(balanceInEther.toString());
    return NumberFormat(_balanceFormat, 'en_US').format(balanceDouble);
  }

  Future<String> sendToken(
    String tokenAddress,
    String fromAddress,
    String toAddress,
    String amount,
    EthPrivateKey credentials,
  ) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(
          json.encode([
            {
              "constant": false,
              "inputs": [
                {"name": "_to", "type": "address"},
                {"name": "_value", "type": "uint256"}
              ],
              "name": "transfer",
              "outputs": [{"name": "", "type": "bool"}],
              "payable": false,
              "stateMutability": "nonpayable",
              "type": "function"
            }
          ]),
          tokenAddress,
        ),
        EthereumAddress.fromHex(tokenAddress),
      );

      final tokenInfo = await getTokenInfo(tokenAddress);
      final amountInWei = BigInt.from(double.parse(amount) * pow(10, tokenInfo.decimals));

      final transferFunction = contract.function('transfer');
      final result = await web3client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: transferFunction,
          parameters: [
            EthereumAddress.fromHex(toAddress),
            amountInWei,
          ],
        ),
        chainId: _sepoliaChainId,
      );

      return result;
    } catch (e) {
      throw Exception('Failed to send token: $e');
    }
  }

  Future<String> sendNativeToken(
    String fromAddress,
    String toAddress,
    String amount,
    EthPrivateKey credentials,
  ) async {
    try {
      final amountInWei = EtherAmount.fromBigInt(
        EtherUnit.wei,
        BigInt.from(double.parse(amount) * pow(10, _nativeTokenDecimals)),
      );

      final result = await web3client.sendTransaction(
        credentials,
        Transaction(
          to: EthereumAddress.fromHex(toAddress),
          from: EthereumAddress.fromHex(fromAddress),
          value: amountInWei,
        ),
        chainId: _sepoliaChainId,
      );

      return result;
    } catch (e) {
      throw Exception('Failed to send native token: $e');
    }
  }

  Future<Map<String, dynamic>> estimateGasFee(
    String fromAddress,
    String toAddress,
    String amount,
    bool isNative,
    String? tokenAddress,
  ) async {
    try {
      final gasPrice = await web3client.getGasPrice();
      BigInt gasLimit;

      if (isNative) {
        final amountInWei = EtherAmount.fromBigInt(
          EtherUnit.wei,
          BigInt.from(double.parse(amount) * pow(10, _nativeTokenDecimals)),
        );

        gasLimit = await web3client.estimateGas(
          sender: EthereumAddress.fromHex(fromAddress),
          to: EthereumAddress.fromHex(toAddress),
          value: amountInWei,
        );
      } else {
        final contract = DeployedContract(
          ContractAbi.fromJson(
            json.encode([
              {
                "constant": false,
                "inputs": [
                  {"name": "_to", "type": "address"},
                  {"name": "_value", "type": "uint256"}
                ],
                "name": "transfer",
                "outputs": [{"name": "", "type": "bool"}],
                "payable": false,
                "stateMutability": "nonpayable",
                "type": "function"
              }
            ]),
            tokenAddress!,
          ),
          EthereumAddress.fromHex(tokenAddress),
        );

        final tokenInfo = await getTokenInfo(tokenAddress);
        final amountInWei = BigInt.from(double.parse(amount) * pow(10, tokenInfo.decimals));
        final transferFunction = contract.function('transfer');

        gasLimit = await web3client.estimateGas(
          sender: EthereumAddress.fromHex(fromAddress),
          to: EthereumAddress.fromHex(tokenAddress),
          data: transferFunction.encodeCall([
            EthereumAddress.fromHex(toAddress),
            amountInWei,
          ]),
        );
      }

      final gasPriceInWei = BigInt.from(gasPrice.getValueInUnit(EtherUnit.wei));
      final totalGasInWei = gasPriceInWei * gasLimit;
      final gasFee = EtherAmount.fromBigInt(EtherUnit.wei, totalGasInWei);

      return {
        'gasPrice': gasPrice.getValueInUnit(EtherUnit.gwei).toStringAsFixed(_gasPriceDecimals),
        'gasLimit': gasLimit.toString(),
        'gasFee': gasFee.getValueInUnit(EtherUnit.ether).toStringAsFixed(_gasFeeDecimals),
      };
    } catch (e) {
      throw Exception('Failed to estimate gas fee: $e');
    }
  }
}