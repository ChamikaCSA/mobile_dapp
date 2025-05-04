import 'package:flutter/material.dart';
import 'package:mobile_dapp/services/wallet_service.dart';
import 'package:mobile_dapp/services/token_service.dart';
import 'package:mobile_dapp/models/token_model.dart';
import 'package:mobile_dapp/widgets/custom_app_bar.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';
import 'package:mobile_dapp/widgets/wallet_secrets_dialog.dart';
import 'package:mobile_dapp/widgets/wallet_card.dart';
import 'package:mobile_dapp/widgets/custom_text_field.dart';
import 'package:mobile_dapp/widgets/custom_button.dart';
import 'package:mobile_dapp/widgets/custom_list_tile.dart';
import 'package:mobile_dapp/utils/clipboard_utils.dart';
import 'package:mobile_dapp/widgets/custom_snackbar.dart';
import 'package:mobile_dapp/utils/animation_constants.dart';
import 'package:mobile_dapp/screens/send_token_screen.dart';
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
    with TickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  final TokenService _tokenService = TokenService();
  final TextEditingController _tokenAddressController = TextEditingController();
  String _balance = '';
  bool _isLoading = false;
  bool _isTokenAddressValid = false;
  final List<TokenModel> _tokens = [];
  bool _isLoadingToken = false;
  bool _isExpanded = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late AnimationController _listAnimationController;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();
    _tokenAddressController.addListener(_validateTokenAddress);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: AnimationConfigs.slideTransition.duration,
      vsync: this,
    );
    _expandController = AnimationController(
      duration: AnimationConfigs.fadeTransition.duration,
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: AnimationConfigs.fadeTransition.duration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AnimationConfigs.slideTransition.curve,
    ));

    _expandAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: AnimationConfigs.fadeTransition.curve,
    ));

    _listAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: AnimationConfigs.fadeTransition.curve,
    ));

    _animationController.forward();
    _slideController.forward();
    _listAnimationController.forward();

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
    _tokenService.dispose();
    _tokenAddressController.removeListener(_validateTokenAddress);
    _tokenAddressController.dispose();
    _animationController.dispose();
    _slideController.dispose();
    _expandController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _getBalance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final balance = await _walletService.getBalance(widget.address);
      final formattedBalance = _walletService.formatBalance(balance);

      setState(() {
        _balance = formattedBalance;
        _isLoading = false;

        final nativeEthIndex = _tokens.indexWhere((token) => token.isNative);
        if (nativeEthIndex >= 0) {
          _tokens[nativeEthIndex] = TokenModel.nativeEth(formattedBalance);
        } else {
          _tokens.insert(0, TokenModel.nativeEth(formattedBalance));
        }
      });

      _animateList();
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

  void _animateList() {
    _listAnimationController.reset();
    _listAnimationController.forward();
  }

  void _validateTokenAddress() {
    final isValid = _tokenService.isValidAddress(_tokenAddressController.text.trim());
    if (isValid != _isTokenAddressValid) {
      setState(() {
        _isTokenAddressValid = isValid;
      });
    }
  }

  Future<void> _importToken() async {
    final tokenAddress = _tokenAddressController.text.trim();

    if (!_isTokenAddressValid) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Invalid token contract address',
          isError: true,
        );
      }
      return;
    }

    setState(() {
      _isLoadingToken = true;
    });

    try {
      final tokenInfo = await _tokenService.getTokenInfo(tokenAddress);
      final balance = await _tokenService.getTokenBalance(tokenAddress, widget.address);

      final token = TokenModel(
        address: tokenInfo.address,
        name: tokenInfo.name,
        symbol: tokenInfo.symbol,
        decimals: tokenInfo.decimals,
        balance: balance,
      );

      setState(() {
        _tokens.add(token);
        _isLoadingToken = false;
      });

      _tokenAddressController.clear();
      _slideController.reset();
      _slideController.forward();
      _animateList();
    } catch (e) {
      setState(() {
        _isLoadingToken = false;
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

  Future<void> _pasteFromClipboard() async {
    final text = await ClipboardUtils.pasteFromClipboard();
    if (text != null) {
      _tokenAddressController.text = text;
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  void _copyAddress() {
    ClipboardUtils.copyToClipboard(context, widget.address);
  }

  Future<void> _showPrivateKeyDialog() async {
    try {
      final privateKey = await _walletService.getPrivateKey(widget.address);
      final wallet = await _walletService.getWallet(widget.address);
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WalletSecretsDialog(
          privateKey: privateKey.privateKeyInt.toRadixString(16).padLeft(64, '0'),
          mnemonic: wallet?.mnemonic,
        ),
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

  Future<void> _showSendTokenDialog(TokenModel token) async {
    if (!widget.isOwnedWallet) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'You can only send tokens from wallets you own',
          isError: true,
        );
      }
      return;
    }

    final txHash = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SendTokenScreen(
          token: token,
          fromAddress: widget.address,
        ),
      ),
    );

    if (txHash != null && mounted) {
      _getBalance();
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
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: CustomCard(
                        child: Column(
                          children: [
                            InkWell(
                              onTap: _toggleExpand,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.token,
                                          color: colorScheme.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Tokens',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    _isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ],
                              ),
                            ),
                            SizeTransition(
                              sizeFactor: _expandAnimation,
                              child: Column(
                                children: [
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _tokenAddressController,
                                    label: 'Token Contract Address',
                                    hint: 'Enter token contract address',
                                    suffixIcon: Icons.paste,
                                    onSuffixIconPressed: _pasteFromClipboard,
                                    isValid: _isTokenAddressValid,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomButton(
                                    onPressed: _isLoadingToken || !_isTokenAddressValid
                                        ? null
                                        : _importToken,
                                    isLoading: _isLoadingToken,
                                    text: 'Import Token',
                                    icon: Icons.add,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_tokens.isNotEmpty)
                    FadeTransition(
                      opacity: _listAnimation,
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _tokens.length,
                        itemBuilder: (context, index) {
                          final token = _tokens[index];
                          final delay = index * 0.1;
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _listAnimationController,
                              curve: Interval(
                                delay,
                                delay + 0.3,
                                curve: AnimationConfigs.slideTransition.curve,
                              ),
                            )),
                            child: FadeTransition(
                              opacity: Tween<double>(
                                begin: 0.0,
                                end: 1.0,
                              ).animate(CurvedAnimation(
                                parent: _listAnimationController,
                                curve: Interval(
                                  delay,
                                  delay + 0.3,
                                  curve: AnimationConfigs.fadeTransition.curve,
                                ),
                              )),
                              child: CustomListTile(
                                title: token.name,
                                subtitle: token.symbol,
                                leadingText: token.symbol,
                                trailingText: token.balance,
                                trailingSubtext: token.symbol,
                                usePrimaryGradient: true,
                                onTap: () => _showSendTokenDialog(token),
                              ),
                            ),
                          );
                        },
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