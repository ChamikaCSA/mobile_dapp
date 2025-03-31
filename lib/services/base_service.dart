import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

abstract class BaseService {
  final String _rpcUrl = 'https://sepolia.infura.io/v3/38ea86d41a0d4ed58fa0fb3a846b81a1';
  late Web3Client _web3client;

  BaseService() {
    _web3client = Web3Client(_rpcUrl, http.Client());
  }

  Web3Client get web3client => _web3client;

  bool isValidAddress(String address) {
    if (address.isEmpty) return false;

    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _web3client.dispose();
  }
}