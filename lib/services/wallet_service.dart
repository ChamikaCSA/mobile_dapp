import 'dart:math';
import 'package:web3dart/web3dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_dapp/models/wallet_model.dart';
import 'package:mobile_dapp/services/wallet_storage_service.dart';
import 'base_service.dart';

class WalletService extends BaseService {
  late final WalletStorageService _storageService;
  bool _isInitialized = false;
  Future<void>? _initFuture;

  WalletService() {
    _initFuture = _initStorage();
  }

  Future<void> _initStorage() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _storageService = WalletStorageService(prefs);
    _isInitialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initFuture;
    }
  }

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

  Future<WalletModel> importWallet(String privateKey, String name) async {
    try {
      await _ensureInitialized();
      final credentials = EthPrivateKey.fromHex(privateKey);

      final wallet = WalletModel(
        address: credentials.address.hex,
        privateKey: privateKey,
        name: name,
        createdAt: DateTime.now(),
      );

      await _storageService.saveWallet(wallet);
      return wallet;
    } catch (e) {
      throw Exception('Failed to import wallet: $e');
    }
  }

  Future<WalletModel> createWallet(String name) async {
    try {
      await _ensureInitialized();
      final credentials = EthPrivateKey.createRandom(Random.secure());

      final wallet = WalletModel(
        address: credentials.address.hex,
        privateKey: credentials.privateKeyInt.toRadixString(16).padLeft(64, '0'),
        name: name,
        createdAt: DateTime.now(),
      );

      await _storageService.saveWallet(wallet);
      return wallet;
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }

  Future<List<WalletModel>> getWallets() async {
    await _ensureInitialized();
    return _storageService.getWallets();
  }

  Future<WalletModel?> getWallet(String address) async {
    await _ensureInitialized();
    return _storageService.getWallet(address);
  }

  Future<void> deleteWallet(String address) async {
    await _ensureInitialized();
    await _storageService.deleteWallet(address);
  }
}