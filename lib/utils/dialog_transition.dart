import 'package:flutter/material.dart';

class CustomDialogTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const CustomDialogTransition({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * animation.value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}