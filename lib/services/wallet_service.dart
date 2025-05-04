import 'dart:math';
import 'package:web3dart/web3dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_dapp/models/wallet_model.dart';
import 'package:mobile_dapp/services/wallet_storage_service.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'base_service.dart';

class WalletService extends BaseService {
  static const String _walletPassword = 'Ua3cPOLzW3kWx9KQpuQ'; // TODO: Implement proper password management
  static const String _derivationPath = "m/44'/60'/0'/0/0"; // BIP44 standard path for Ethereum
  static const int _balanceDecimals = 4;

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
    return balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(_balanceDecimals);
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

  bool isValidMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  Future<WalletModel> importWallet(String privateKey, String name) async {
    try {
      await _ensureInitialized();
      final credentials = EthPrivateKey.fromHex(privateKey);

      final wallet = Wallet.createNew(
        credentials,
        _walletPassword,
        Random.secure(),
      );

      final walletModel = WalletModel(
        address: credentials.address.hex,
        encryptedData: wallet.toJson(),
        name: name,
        createdAt: DateTime.now(),
      );

      await _storageService.saveWallet(walletModel);
      return walletModel;
    } catch (e) {
      throw Exception('Failed to import wallet: $e');
    }
  }

  Future<WalletModel> importWalletFromMnemonic(
      String mnemonic, String name) async {
    try {
      await _ensureInitialized();

      if (!isValidMnemonic(mnemonic)) {
        throw Exception('Invalid mnemonic phrase');
      }

      return _createWalletFromMnemonic(mnemonic, name);
    } catch (e) {
      throw Exception('Failed to import wallet from mnemonic: $e');
    }
  }

    Future<WalletModel> createWallet(String name) async {
    try {
      await _ensureInitialized();

      final mnemonic = bip39.generateMnemonic();
      return _createWalletFromMnemonic(mnemonic, name);
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }

  Future<WalletModel> _createWalletFromMnemonic(String mnemonic, String name) async {
    try {
      final credentials = derivePrivateKey(mnemonic);

      final wallet = Wallet.createNew(
        credentials,
        _walletPassword,
        Random.secure(),
      );

      final walletModel = WalletModel(
        address: credentials.address.hex,
        encryptedData: wallet.toJson(),
        name: name,
        createdAt: DateTime.now(),
        mnemonic: mnemonic,
      );

      await _storageService.saveWallet(walletModel);
      return walletModel;
    } catch (e) {
      throw Exception('Failed to create wallet from mnemonic: $e');
    }
  }

    EthPrivateKey derivePrivateKey(String mnemonic) {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);

    final child = root.derivePath(_derivationPath);

    final privateKey = HEX.encode(child.privateKey!);
    return EthPrivateKey.fromHex(privateKey);
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

  Future<EthPrivateKey> getPrivateKey(String address) async {
    try {
      await _ensureInitialized();
      final walletModel = await _storageService.getWallet(address);
      if (walletModel == null) {
        throw Exception('Wallet not found');
      }

      final wallet =
          Wallet.fromJson(walletModel.encryptedData, _walletPassword);
      return wallet.privateKey;
    } catch (e) {
      throw Exception('Failed to get private key: $e');
    }
  }
}
