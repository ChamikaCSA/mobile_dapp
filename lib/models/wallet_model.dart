import 'package:flutter/foundation.dart';
import 'package:mobile_dapp/services/wallet_service.dart';

class WalletModel extends ChangeNotifier {
  final WalletService _walletService = WalletService();
  String _address = '';
  String _balance = '';
  bool _isLoading = false;
  String _errorMessage = '';

  String get address => _address;
  String get balance => _balance;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  void setAddress(String address) {
    _address = address.trim();
    notifyListeners();
  }

  Future<void> getBalance() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final balance = await _walletService.getBalance(_address);
      _balance = _walletService.formatBalance(balance);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _balance = '';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _address = '';
    _balance = '';
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _walletService.dispose();
    super.dispose();
  }
}