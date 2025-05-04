import 'package:flutter/material.dart';
import 'package:mobile_dapp/models/token_model.dart';
import 'package:mobile_dapp/widgets/custom_text_field.dart';
import 'package:mobile_dapp/widgets/custom_button.dart';
import 'package:mobile_dapp/utils/clipboard_utils.dart';
import 'package:mobile_dapp/services/token_service.dart';
import 'package:mobile_dapp/services/wallet_service.dart';
import 'package:mobile_dapp/widgets/custom_snackbar.dart';
import 'package:mobile_dapp/widgets/custom_app_bar.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';
import 'package:mobile_dapp/utils/animation_constants.dart';

class SendTokenScreen extends StatefulWidget {
  final TokenModel token;
  final String fromAddress;

  const SendTokenScreen({
    super.key,
    required this.token,
    required this.fromAddress,
  });

  @override
  State<SendTokenScreen> createState() => _SendTokenScreenState();
}

class _SendTokenScreenState extends State<SendTokenScreen>
    with TickerProviderStateMixin {
  final TextEditingController _toAddressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TokenService _tokenService = TokenService();
  final WalletService _walletService = WalletService();
  bool _isToAddressValid = false;
  bool _isAmountValid = false;
  bool _isLoading = false;
  bool _isEstimatingGas = false;
  Map<String, dynamic>? _gasEstimate;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _toAddressController.addListener(_validateToAddress);
    _amountController.addListener(_validateAmount);

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AnimationConfigs.slideTransition.curve,
    ));

    _animationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _toAddressController.removeListener(_validateToAddress);
    _amountController.removeListener(_validateAmount);
    _toAddressController.dispose();
    _amountController.dispose();
    _tokenService.dispose();
    _walletService.dispose();
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _validateToAddress() {
    final isValid = _tokenService.isValidAddress(_toAddressController.text.trim());
    if (isValid != _isToAddressValid) {
      setState(() {
        _isToAddressValid = isValid;
      });
      _estimateGas();
    }
  }

  void _validateAmount() {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      setState(() {
        _isAmountValid = false;
      });
      return;
    }

    try {
      final double amountDouble = double.parse(amount);
      final double balanceDouble = double.parse(widget.token.balance);
      setState(() {
        _isAmountValid = amountDouble > 0 && amountDouble <= balanceDouble;
      });
      _estimateGas();
    } catch (e) {
      setState(() {
        _isAmountValid = false;
      });
    }
  }

  Future<void> _estimateGas() async {
    if (!_isToAddressValid || !_isAmountValid) {
      setState(() {
        _gasEstimate = null;
      });
      return;
    }

    setState(() {
      _isEstimatingGas = true;
    });

    try {
      final estimate = await _tokenService.estimateGasFee(
        widget.fromAddress,
        _toAddressController.text.trim(),
        _amountController.text.trim(),
        widget.token.isNative,
        widget.token.isNative ? null : widget.token.address,
      );

      if (mounted) {
        setState(() {
          _gasEstimate = estimate;
          _isEstimatingGas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gasEstimate = null;
          _isEstimatingGas = false;
        });
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final text = await ClipboardUtils.pasteFromClipboard();
    if (text != null) {
      _toAddressController.text = text;
    }
  }

  Future<void> _sendToken() async {
    if (!_isToAddressValid || !_isAmountValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final privateKey = await _walletService.getPrivateKey(widget.fromAddress);
      final toAddress = _toAddressController.text.trim();
      final amount = _amountController.text.trim();

      String txHash;
      if (widget.token.isNative) {
        txHash = await _tokenService.sendNativeToken(
          widget.fromAddress,
          toAddress,
          amount,
          privateKey,
        );
      } else {
        txHash = await _tokenService.sendToken(
          widget.token.address,
          widget.fromAddress,
          toAddress,
          amount,
          privateKey,
        );
      }

      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Transaction sent successfully!',
          isError: false,
        );
        Navigator.of(context).pop(txHash);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
            title: 'Send ${widget.token.symbol}',
            icon: Icons.swap_horiz,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Recipient Details',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            CustomTextField(
                              controller: _toAddressController,
                              label: 'To Address',
                              hint: 'Enter recipient address',
                              suffixIcon: Icons.paste,
                              onSuffixIconPressed: _pasteFromClipboard,
                              isValid: _isToAddressValid,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.payments,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Amount Details',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            CustomTextField(
                              controller: _amountController,
                              label: 'Amount',
                              hint: 'Enter amount to send',
                              keyboardType: TextInputType.number,
                              isValid: _isAmountValid,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Available: ${widget.token.balance} ${widget.token.symbol}',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            if (_isEstimatingGas)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Estimating network fee...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_gasEstimate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.outline.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.speed,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Network Fee',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Fee Amount',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                          Text(
                                            '${_gasEstimate!['gasFee']} ETH',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Gas Price',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                          Text(
                                            '${_gasEstimate!['gasPrice']} Gwei',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CustomButton(
                          onPressed: _isLoading || !_isToAddressValid || !_isAmountValid
                              ? null
                              : _sendToken,
                          isLoading: _isLoading,
                          text: 'Send',
                          icon: Icons.send,
                        ),
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