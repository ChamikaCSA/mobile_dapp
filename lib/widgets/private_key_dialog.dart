import 'package:flutter/material.dart';
import 'package:mobile_dapp/utils/clipboard_utils.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';
import 'package:mobile_dapp/utils/dialog_transition.dart';
import 'dart:async';

class PrivateKeyDialog extends StatefulWidget {
  final String privateKey;

  const PrivateKeyDialog({
    super.key,
    required this.privateKey,
  });

  @override
  State<PrivateKeyDialog> createState() => _PrivateKeyDialogState();
}

class _PrivateKeyDialogState extends State<PrivateKeyDialog> with TickerProviderStateMixin {
  bool _isPrivateKeyRevealed = false;
  bool _isHoldingButton = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _dialogController;
  late Animation<double> _dialogAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _dialogAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: Curves.easeInOut,
    );

    _dialogController.forward();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulseController.dispose();
    _dialogController.dispose();
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

      _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _holdProgress = (_holdProgress + 0.05).clamp(0.0, 1.0);
          if (_holdProgress >= 1.0) {
            _revealPrivateKey();
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

  void _revealPrivateKey() {
    if (!mounted) return;

    Future.microtask(() {
      if (!mounted) return;
      setState(() {
        _isPrivateKeyRevealed = true;
      });
    });
  }

  void _copyPrivateKey() {
    ClipboardUtils.copyToClipboard(context, widget.privateKey);
  }

  Future<void> _closeDialog() async {
    await _dialogController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async {
        await _closeDialog();
        return false;
      },
      child: Dialog(
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
                          'Private Key',
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
                if (!_isPrivateKeyRevealed) ...[
                  Text(
                    'Hold the button below to reveal your private key. Make sure you are in a private location and no one can see your screen.',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTapDown: (_) => _startHolding(),
                    onTapUp: (_) => _stopHolding(),
                    onTapCancel: () => _stopHolding(),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isHoldingButton ? 1.0 : _pulseAnimation.value,
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                if (_isHoldingButton)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CustomPaint(
                                        painter: _ProgressPainter(
                                          progress: _holdProgress,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isHoldingButton)
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              colorScheme.onPrimary,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isHoldingButton ? 'Revealing...' : 'Hold to Reveal Private Key',
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.privateKey,
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(Icons.copy, color: colorScheme.onSurfaceVariant),
                          onPressed: _copyPrivateKey,
                          tooltip: 'Copy private key',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Never share your private key with anyone.',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _closeDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: colorScheme.onPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'I have saved my private key',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
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
