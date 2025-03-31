import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool usePrimaryGradient;
  final double elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.usePrimaryGradient = false,
    this.elevation = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: usePrimaryGradient
                ? [
                    colorScheme.primaryContainer,
                    colorScheme.primary.withAlpha(204),
                  ]
                : [
                    colorScheme.surface,
                    colorScheme.surfaceContainerHighest,
                  ],
          ),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20.0),
          child: child,
        ),
      ),
    );
  }
}