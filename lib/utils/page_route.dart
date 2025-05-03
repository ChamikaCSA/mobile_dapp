import 'package:flutter/material.dart';
import 'package:mobile_dapp/utils/animation_constants.dart';

class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  CustomPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final config = AnimationConfigs.pageTransition;
            var fadeAnimation = animation.drive(
              Tween<double>(begin: 0.0, end: 1.0).chain(
                CurveTween(curve: config.curve),
              ),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: child,
            );
          },
          transitionDuration: AnimationConfigs.pageTransition.duration,
          reverseTransitionDuration: AnimationConfigs.pageTransition.duration,
        );
}