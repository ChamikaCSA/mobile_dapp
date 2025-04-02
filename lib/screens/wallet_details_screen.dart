import 'package:flutter/material.dart';
import 'package:mobile_dapp/services/wallet_service.dart';
import 'package:mobile_dapp/widgets/custom_app_bar.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';
import 'package:mobile_dapp/widgets/private_key_dialog.dart';
import 'package:mobile_dapp/widgets/token_manager.dart';
import 'package:mobile_dapp/widgets/wallet_card.dart';
import 'package:mobile_dapp/utils/clipboard_utils.dart';
import 'package:mobile_dapp/widgets/custom_snackbar.dart';
import 'dart:async';

class WalletDetailsScreen extends StatefulWidget {
  final String address;
  final bool isNewWallet;
  final bool isOwnedWallet;

  const WalletDetailsScreen({
    super.key,
    required this.address,
    this.isNewWallet = false,
    this.isOwnedWallet = false,
  });

  @override
  State<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends State<WalletDetailsScreen>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  String _balance = '';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    _getBalance();

    if (widget.isNewWallet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPrivateKeyDialog();
      });
    }
  }

  @override
  void dispose() {
    _walletService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getBalance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final balance = await _walletService.getBalance(widget.address);
      setState(() {
        _balance = _walletService.formatBalance(balance);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _balance = '';
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  void _copyAddress() {
    ClipboardUtils.copyToClipboard(context, widget.address);
  }

  Future<void> _showPrivateKeyDialog() async {
    try {
      final privateKey = await _walletService.getPrivateKey(widget.address);
      if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
        builder: (context) => PrivateKeyDialog(privateKey: privateKey.privateKeyInt.toRadixString(16).padLeft(64, '0')),
    );
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: 'Wallet Details',
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
                                    'Wallet Address',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  if (widget.isOwnedWallet)
                                    IconButton(
                                      icon: Icon(Icons.key, color: colorScheme.tertiary),
                                      onPressed: _showPrivateKeyDialog,
                                      tooltip: 'Show private key',
                                    ),
                                  IconButton(
                                    icon: Icon(Icons.copy, color: colorScheme.onSurface),
                                    onPressed: _copyAddress,
                                    tooltip: 'Copy address',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${widget.address.substring(0, 7)}...${widget.address.substring(widget.address.length - 5)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onPrimaryContainer,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  WalletCard(
                    balance: _balance,
                    isLoading: _isLoading,
                    onRefresh: _getBalance,
                    animation: _fadeAnimation,
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: TokenManager(
                      walletAddress: widget.address,
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