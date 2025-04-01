import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_dapp/services/wallet_service.dart';
import 'package:mobile_dapp/widgets/custom_app_bar.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';
import 'package:mobile_dapp/widgets/custom_text_field.dart';
import 'package:mobile_dapp/widgets/error_card.dart';
import 'package:mobile_dapp/widgets/custom_button.dart';
import 'package:mobile_dapp/utils/clipboard_utils.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  final WalletService _walletService = WalletService();
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isWalletAddressValid = false;
  bool _isPrivateKeyValid = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _addressController.addListener(_validateWalletAddress);
    _privateKeyController.addListener(_validatePrivateKey);
  }

  void _validateWalletAddress() {
    final isValid =
        _walletService.isValidAddress(_addressController.text.trim());
    if (isValid != _isWalletAddressValid) {
      setState(() {
        _isWalletAddressValid = isValid;
      });
    }
  }

  void _validatePrivateKey() {
    final isValid =
        _walletService.isValidPrivateKey(_privateKeyController.text.trim());
    if (isValid != _isPrivateKeyValid) {
      setState(() {
        _isPrivateKeyValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _addressController.removeListener(_validateWalletAddress);
    _privateKeyController.removeListener(_validatePrivateKey);
    _addressController.dispose();
    _privateKeyController.dispose();
    _walletService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getBalance() async {
    final address = _addressController.text.trim();

    if (!_isWalletAddressValid) {
      setState(() {
        _errorMessage = 'Invalid wallet address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      setState(() {
        _isLoading = false;
        _addressController.clear();
        _privateKeyController.clear();
      });
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/wallet-details',
          arguments: {
            'address': address,
            'privateKey': null,
            'isNewWallet': false,
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _importWallet() async {
    final privateKey = _privateKeyController.text.trim();

    if (!_isPrivateKeyValid) {
      setState(() {
        _errorMessage = 'Invalid private key';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final address = await _walletService.importWallet(privateKey);
      setState(() {
        _isLoading = false;
        _addressController.clear();
        _privateKeyController.clear();
      });
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/wallet-details',
          arguments: {
            'address': address,
            'privateKey': privateKey,
            'isNewWallet': false,
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createWallet() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final wallet = await _walletService.createWallet();
      setState(() {
        _isLoading = false;
        _addressController.clear();
        _privateKeyController.clear();
      });
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/wallet-details',
          arguments: {
            'address': wallet['address']!,
            'privateKey': wallet['privateKey'],
            'isNewWallet': true,
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final text = await ClipboardUtils.pasteFromClipboard();
    if (text != null) {
      _addressController.text = text;
    }
  }

  Future<void> _pastePrivateKeyFromClipboard() async {
    final text = await ClipboardUtils.pasteFromClipboard();
    if (text != null) {
      _privateKeyController.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: 'Wallet',
            icon: Icons.account_balance_wallet,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeTransition(
                      opacity: _fadeAnimation,
                      child: CustomCard(
                        height: 240,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.wallet,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Check Wallet Balance',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            CustomTextField(
                              controller: _addressController,
                              hintText: 'Enter wallet address',
                              isValid: _isWalletAddressValid,
                              onPaste: _pasteFromClipboard,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    onPressed:
                                        _isLoading || !_isWalletAddressValid
                                            ? null
                                            : _getBalance,
                                    isLoading: _isLoading,
                                    text: 'Check Balance',
                                    icon:
                                        CupertinoIcons.money_dollar_circle_fill,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: CustomCard(
                      height: 240,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.key,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Import Existing Wallet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          CustomTextField(
                            controller: _privateKeyController,
                            hintText: 'Enter private key',
                            isValid: _isPrivateKeyValid,
                            obscureText: true,
                            onPaste: _pastePrivateKeyFromClipboard,
                          ),
                          CustomButton(
                            onPressed: _isLoading || !_isPrivateKeyValid
                                ? null
                                : _importWallet,
                            isLoading: _isLoading,
                            text: 'Import Wallet',
                            icon: Icons.file_download,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: CustomCard(
                      child: CustomButton(
                        onPressed: _isLoading ? null : _createWallet,
                        isLoading: _isLoading,
                        text: 'Create New Wallet',
                        icon: Icons.add_circle,
                      ),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ErrorCard(
                        message: _errorMessage,
                        animation: _fadeAnimation,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
