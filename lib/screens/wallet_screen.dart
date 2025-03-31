import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_dapp/services/wallet_service.dart';
import 'package:mobile_dapp/screens/token_screen.dart';
import 'package:mobile_dapp/widgets/custom_app_bar.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';
import 'package:mobile_dapp/widgets/custom_text_field.dart';
import 'package:mobile_dapp/widgets/error_card.dart';
import 'package:mobile_dapp/widgets/loading_button.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _addressController = TextEditingController();
  final WalletService _walletService = WalletService();
  String _balance = '';
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isWalletAddressValid = false;

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
  }

  void _validateWalletAddress() {
    final isValid = _walletService.isValidAddress(_addressController.text.trim());
    if (isValid != _isWalletAddressValid) {
      setState(() {
        _isWalletAddressValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _addressController.removeListener(_validateWalletAddress);
    _addressController.dispose();
    _walletService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getBalance() async {
    final address = _addressController.text.trim();

    if (!_isWalletAddressValid) {
      setState(() {
        _errorMessage = 'Invalid wallet address';
        _balance = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final balance = await _walletService.getBalance(address);
      setState(() {
        _balance = _walletService.formatBalance(balance);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _balance = '';
        _isLoading = false;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _addressController.text = clipboardData!.text!;
    }
  }

  void _copyBalance() {
    Clipboard.setData(ClipboardData(text: _balance));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Balance copied to clipboard',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _navigateToTokenScreen() {
    if (!_isWalletAddressValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid wallet address first',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TokenScreen(
          walletAddress: _addressController.text.trim(),
        ),
      ),
    );
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                'Enter Wallet Address',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _addressController,
                            hintText: '0x...',
                            isValid: _isWalletAddressValid,
                            onPaste: _pasteFromClipboard,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: LoadingButton(
                                  onPressed: _isLoading || !_isWalletAddressValid ? null : _getBalance,
                                  isLoading: _isLoading,
                                  text: 'Check Balance',
                                  icon: CupertinoIcons.money_dollar_circle_fill,
                                ),
                              ),
                              const SizedBox(width: 12),
                              LoadingButton(
                                onPressed: _isLoading || !_isWalletAddressValid ? null : _navigateToTokenScreen,
                                isLoading: false,
                                text: 'Tokens',
                                icon: Icons.token,
                                backgroundColor: colorScheme.secondary,
                                foregroundColor: colorScheme.onSecondary,
                              ),
                            ],
                          ),
                        ],
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
                  if (_balance.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: CustomCard(
                        usePrimaryGradient: true,
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: colorScheme.onPrimaryContainer,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Wallet Balance',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.copy, color: colorScheme.onPrimaryContainer),
                                  onPressed: _copyBalance,
                                  tooltip: 'Copy balance',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '$_balance SepoliaETH',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
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