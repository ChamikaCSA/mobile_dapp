import 'dart:math';
import 'package:web3dart/web3dart.dart';
import 'base_service.dart';

class WalletService extends BaseService {

  Future<EtherAmount> getBalance(String address) async {
    try {
      final walletAddress = EthereumAddress.fromHex(address);
      final balance = await web3client.getBalance(walletAddress);
      return balance;
    } catch (e) {
      throw Exception('Failed to get balance: $e');
    }
  }

  String formatBalance(EtherAmount balance) {
    return balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(4);
  }

  bool isValidPrivateKey(String privateKey) {
    if (privateKey.isEmpty) return false;

    try {
      EthPrivateKey.fromHex(privateKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> importWallet(String privateKey) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      return credentials.address.hex;
    } catch (e) {
      throw Exception('Failed to import wallet: $e');
    }
  }

  Future<Map<String, String>> createWallet() async {
    try {
      final credentials = EthPrivateKey.createRandom(Random.secure());
      final result = {
        'address': credentials.address.hex,
        'privateKey': credentials.privateKeyInt.toRadixString(16).padLeft(64, '0'),
      };

      return result;
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }
}