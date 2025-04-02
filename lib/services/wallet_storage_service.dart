import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_dapp/models/wallet_model.dart';

class WalletStorageService {
  static const String _walletsKey = 'wallets';
  final SharedPreferences _prefs;

  WalletStorageService(this._prefs);

  Future<List<WalletModel>> getWallets() async {
    try {
      final String? walletsJson = _prefs.getString(_walletsKey);
      if (walletsJson == null) return [];

      final List<dynamic> walletsList =
          json.decode(walletsJson) as List<dynamic>;
      return walletsList
          .map((json) => WalletModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<WalletModel?> getWallet(String address) async {
    try {
      final wallets = await getWallets();
      return wallets.firstWhere((w) => w.address == address);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveWallet(WalletModel wallet) async {
    try {
      final wallets = await getWallets();
      wallets.add(wallet);

      final walletsJson = json.encode(wallets.map((w) => w.toJson()).toList());

      await _prefs.setString(_walletsKey, walletsJson);
    } catch (e) {
      throw Exception('Failed to save wallet: $e');
    }
  }

  Future<void> deleteWallet(String address) async {
    try {
      final wallets = await getWallets();
      wallets.removeWhere((w) => w.address == address);

      final walletsJson = json.encode(wallets.map((w) => w.toJson()).toList());
      await _prefs.setString(_walletsKey, walletsJson);
    } catch (e) {
      throw Exception('Failed to delete wallet: $e');
    }
  }
}
