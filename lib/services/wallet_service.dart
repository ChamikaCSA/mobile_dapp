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
}