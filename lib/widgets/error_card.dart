import 'package:flutter/material.dart';

class ErrorCard extends StatelessWidget {
  final String message;
  final Animation<double>? animation;

  const ErrorCard({
    super.key,
    required this.message,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget card = Card(
      color: colorScheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onErrorContainer,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (animation != null) {
      card = FadeTransition(
        opacity: animation!,
        child: card,
      );
    }

    return card;
  }
}