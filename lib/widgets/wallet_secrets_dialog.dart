import 'package:flutter/material.dart';
import 'package:mobile_dapp/utils/clipboard_utils.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';
import 'package:mobile_dapp/utils/dialog_transition.dart';
import 'dart:async';
import 'package:mobile_dapp/utils/animation_constants.dart';

class WalletSecretsDialog extends StatefulWidget {
  final String privateKey;
  final String? mnemonic;

  const WalletSecretsDialog({
    super.key,
    required this.privateKey,
    this.mnemonic,
  });

  @override
  State<WalletSecretsDialog> createState() => _WalletSecretsDialogState();
}

class _WalletSecretsDialogState extends State<WalletSecretsDialog> with TickerProviderStateMixin {
  bool _isRevealed = false;
  bool _isHoldingButton = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _dialogController;
  late Animation<double> _dialogAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: AnimationConfigs.pulseAnimation.duration,
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: AnimationConfigs.pulseAnimation.curve,
      ),
    );

    _dialogController = AnimationController(
      duration: AnimationConfigs.dialogTransition.duration,
      vsync: this,
    );

    _dialogAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: AnimationConfigs.dialogTransition.curve,
    );

    _dialogController.forward();

    _tabController = TabController(
      length: widget.mnemonic != null ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulseController.dispose();
    _dialogController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _startHolding() {
    if (!mounted) return;

    Future.microtask(() {
      if (!mounted) return;
      setState(() {
        _isHoldingButton = true;
        _holdProgress = 0.0;
      });

      _holdTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _holdProgress = (_holdProgress + 0.02).clamp(0.0, 1.0);
          if (_holdProgress >= 1.0) {
            _revealSecrets();
            timer.cancel();
          }
        });
      });
    });
  }

  void _stopHolding() {
    _holdTimer?.cancel();
    if (!mounted) return;

    Future.microtask(() {
      if (!mounted) return;
      setState(() {
        _isHoldingButton = false;
        _holdProgress = 0.0;
      });
    });
  }

  void _revealSecrets() {
    if (!mounted) return;

    Future.microtask(() {
      if (!mounted) return;
      setState(() {
        _isRevealed = true;
      });
    });
  }

  void _copyPrivateKey() {
    ClipboardUtils.copyToClipboard(context, widget.privateKey);
  }

  void _copyMnemonic() {
    if (widget.mnemonic != null) {
      ClipboardUtils.copyToClipboard(context, widget.mnemonic!);
    }
  }

  Future<void> _closeDialog() async {
    await _dialogController.reverse();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: CustomDialogTransition(
        animation: _dialogAnimation,
        child: CustomCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.key,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Wallet Secrets',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    onPressed: _closeDialog,
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Never share your private key or mnemonic phrase with anyone. Anyone with access to these can control your wallet and funds.',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!_isRevealed)
                GestureDetector(
                  onTapDown: (_) => _startHolding(),
                  onTapUp: (_) => _stopHolding(),
                  onTapCancel: _stopHolding,
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _isHoldingButton ? 'Revealing...' : 'Hold to Reveal Secrets',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (_isHoldingButton)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CustomPaint(
                                painter: _ProgressPainter(
                                  progress: _holdProgress,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else ...[
                TabBar(
                  controller: _tabController,
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    Tab(text: 'Private Key'),
                    if (widget.mnemonic != null) Tab(text: 'Mnemonic Phrase'),
                  ],
                ),
                SizedBox(
                  height: 160,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.primary),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Private Key',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.copy, color: colorScheme.primary),
                                  onPressed: _copyPrivateKey,
                                  tooltip: 'Copy private key',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  widget.privateKey,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.mnemonic != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.primary),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Mnemonic Phrase',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.copy, color: colorScheme.primary),
                                    onPressed: _copyMnemonic,
                                    tooltip: 'Copy mnemonic phrase',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    widget.mnemonic!,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 14,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width * progress, size.height);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
