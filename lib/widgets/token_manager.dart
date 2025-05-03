import 'package:flutter/material.dart';
import 'package:mobile_dapp/services/token_service.dart';
import 'package:mobile_dapp/models/token_model.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';
import 'package:mobile_dapp/widgets/custom_text_field.dart';
import 'package:mobile_dapp/widgets/custom_button.dart';
import 'package:mobile_dapp/utils/clipboard_utils.dart';
import 'package:mobile_dapp/widgets/custom_snackbar.dart';
import 'package:mobile_dapp/services/wallet_service.dart';
import 'package:mobile_dapp/widgets/custom_list_tile.dart';
import 'package:mobile_dapp/utils/animation_constants.dart';

class TokenManager extends StatefulWidget {
  final String walletAddress;
  final Animation<double> animation;

  const TokenManager({
    super.key,
    required this.walletAddress,
    required this.animation,
  });

  @override
  State<TokenManager> createState() => _TokenManagerState();
}

class _TokenManagerState extends State<TokenManager> with TickerProviderStateMixin {
  final TextEditingController _tokenAddressController = TextEditingController();
  final TokenService _tokenService = TokenService();
  final WalletService _walletService = WalletService();
  bool _isTokenAddressValid = false;
  final List<TokenModel> _tokens = [];
  bool _isLoadingToken = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late AnimationController _listAnimationController;
  late Animation<double> _listAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tokenAddressController.addListener(_validateTokenAddress);
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
    _slideController.forward();
    _listAnimationController.forward();
    _loadNativeEthBalance();
  }

  Future<void> _loadNativeEthBalance() async {
    try {
      final balance = await _walletService.getBalance(widget.walletAddress);
      final formattedBalance = _walletService.formatBalance(balance);
      setState(() {
        _tokens.insert(0, TokenModel.nativeEth(formattedBalance));
      });
      _animateList();
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Failed to load ETH balance: $e',
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
    final isValid =
        _tokenService.isValidAddress(_tokenAddressController.text.trim());
    if (isValid != _isTokenAddressValid) {
      setState(() {
        _isTokenAddressValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _tokenAddressController.removeListener(_validateTokenAddress);
    _tokenAddressController.dispose();
    _tokenService.dispose();
    _slideController.dispose();
    _expandController.dispose();
    _listAnimationController.dispose();
    super.dispose();
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
      final balance = await _tokenService.getTokenBalance(
          tokenAddress, widget.walletAddress);

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: widget.animation,
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
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
