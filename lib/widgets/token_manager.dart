import 'package:flutter/material.dart';
import 'package:mobile_dapp/services/token_service.dart';
import 'package:mobile_dapp/models/token_model.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';
import 'package:mobile_dapp/widgets/custom_text_field.dart';
import 'package:mobile_dapp/widgets/custom_button.dart';
import 'package:mobile_dapp/utils/clipboard_utils.dart';
import 'package:mobile_dapp/widgets/custom_snackbar.dart';
import 'dart:math';

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
  bool _isTokenAddressValid = false;
  final List<TokenModel> _tokens = [];
  bool _isLoadingToken = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tokenAddressController.addListener(_validateTokenAddress);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _expandAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    ));
    _slideController.forward();
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Token Management',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${_tokens.length} tokens',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        RotationTransition(
                          turns: _expandAnimation,
                          child: Icon(
                            Icons.expand_more,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Column(
                      children: [
                        const Divider(
                          height: 40,
                        ),
                        Column(
                          children: [
                            CustomTextField(
                              controller: _tokenAddressController,
                              hintText: 'Enter token contract address',
                              isValid: _isTokenAddressValid,
                              onPaste: _pasteFromClipboard,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                onPressed: _isLoadingToken || !_isTokenAddressValid
                                    ? null
                                    : _importToken,
                                isLoading: _isLoadingToken,
                                text: 'Import Token',
                                icon: Icons.add_circle_outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_tokens.isNotEmpty) ...[
          const SizedBox(height: 16),
          FadeTransition(
            opacity: widget.animation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomCard(
                usePrimaryGradient: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Tokens',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tokens.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final token = _tokens[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimaryContainer.withAlpha(26),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.onPrimaryContainer.withAlpha(52),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primary.withOpacity(0.1),
                              child: Text(
                                token.symbol[0].toUpperCase(),
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              token.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            subtitle: Text(
                              token.symbol,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  (BigInt.parse(token.balance) / BigInt.from(pow(10, token.decimals))).toStringAsFixed(4).replaceAll(RegExp(r'\.?0*$'), ''),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  token.symbol,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onPrimaryContainer.withOpacity(0.7),
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
          ),
        ],
      ],
    );
  }
}
