import 'package:flutter/material.dart';
import 'package:mobile_dapp/services/wallet_service.dart';
import 'package:mobile_dapp/widgets/custom_app_bar.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';
import 'package:mobile_dapp/widgets/error_card.dart';
import 'package:mobile_dapp/widgets/private_key_dialog.dart';
import 'package:mobile_dapp/widgets/token_manager.dart';
import 'package:mobile_dapp/utils/clipboard_utils.dart';
import 'dart:async';

class WalletDetailsScreen extends StatefulWidget {
  final String address;
  final String? privateKey;
  final bool isNewWallet;

  const WalletDetailsScreen({
    super.key,
    required this.address,
    this.privateKey,
    this.isNewWallet = false,
  });

  @override
  State<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends State<WalletDetailsScreen>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  String _balance = '';
  bool _isLoading = false;
  String _errorMessage = '';
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

    if (widget.privateKey != null && widget.isNewWallet) {
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
      _errorMessage = '';
    });

    try {
      final balance = await _walletService.getBalance(widget.address);
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

  void _copyAddress() {
    ClipboardUtils.copyToClipboard(context, widget.address);
  }

  void _showPrivateKeyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrivateKeyDialog(privateKey: widget.privateKey!),
    );
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
                                  if (widget.privateKey != null)
                                    IconButton(
                                      icon: Icon(Icons.key,
                                          color: colorScheme.primary),
                                      onPressed: _showPrivateKeyDialog,
                                      tooltip: 'Access private key',
                                    ),
                                  IconButton(
                                    icon: Icon(Icons.copy,
                                        color: colorScheme.onSurface),
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
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: CustomCard(
                      usePrimaryGradient: true,
                      height: 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Sepolia',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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
                                icon: _isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      )
                                    : Icon(Icons.refresh,
                                        color: colorScheme.onPrimaryContainer),
                                onPressed: _getBalance,
                                tooltip: 'Refresh balance',
                                iconSize: 24,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  _balance,
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SepoliaETH',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: colorScheme.onPrimaryContainer
                                      .withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onPrimaryContainer
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: TokenManager(
                      walletAddress: widget.address,
                      animation: _fadeAnimation,
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