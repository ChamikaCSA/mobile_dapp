import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_dapp/services/token_service.dart';
import 'package:mobile_dapp/models/token_model.dart';
import 'package:mobile_dapp/widgets/custom_app_bar.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';
import 'package:mobile_dapp/widgets/custom_text_field.dart';
import 'package:mobile_dapp/widgets/error_card.dart';
import 'package:mobile_dapp/widgets/loading_button.dart';
import 'dart:math';

class TokenScreen extends StatefulWidget {
  final String walletAddress;

  const TokenScreen({
    super.key,
    required this.walletAddress,
  });

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _tokenAddressController = TextEditingController();
  final TokenService _tokenService = TokenService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isTokenAddressValid = false;
  final List<TokenModel> _tokens = [];
  bool _isLoadingToken = false;
  String _tokenErrorMessage = '';

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

    _tokenAddressController.addListener(_validateTokenAddress);
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _importToken() async {
    final tokenAddress = _tokenAddressController.text.trim();

    if (!_isTokenAddressValid) {
      setState(() {
        _tokenErrorMessage = 'Invalid token contract address';
      });
      return;
    }

    setState(() {
      _isLoadingToken = true;
      _tokenErrorMessage = '';
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
    } catch (e) {
      setState(() {
        _tokenErrorMessage = e.toString();
        _isLoadingToken = false;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _tokenAddressController.text = clipboardData!.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: 'Tokens',
            icon: Icons.token,
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
                                Icons.assignment,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Enter Token Contract Address',
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
                            controller: _tokenAddressController,
                            hintText: '0x...',
                            isValid: _isTokenAddressValid,
                            onPaste: _pasteFromClipboard,
                          ),
                          const SizedBox(height: 20),
                          LoadingButton(
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
                  ),
                  if (_tokenErrorMessage.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ErrorCard(
                        message: _tokenErrorMessage,
                        animation: _fadeAnimation,
                      ),
                    ),
                  if (_tokens.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: CustomCard(
                        usePrimaryGradient: true,
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.token,
                                  color: colorScheme.onPrimaryContainer,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Imported Tokens',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _tokens.length,
                              itemBuilder: (context, index) {
                                final token = _tokens[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  color: colorScheme.onPrimaryContainer
                                      .withAlpha(26),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Text(
                                              token.name,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                            ),
                                            Text(
                                              token.symbol,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${(BigInt.parse(token.balance) / BigInt.from(pow(10, token.decimals))).toStringAsFixed(4).replaceAll(RegExp(r'\.?0*$'), '')} ${token.symbol}',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
