import 'package:flutter/material.dart';

class CustomSnackBar extends StatelessWidget {
  final String message;
  final bool isError;
  final Duration duration;
  final VoidCallback? onDismissed;

  const CustomSnackBar({
    super.key,
    required this.message,
    this.isError = true,
    this.duration = const Duration(seconds: 4),
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isError ? colorScheme.error : colorScheme.primary;
    final width = MediaQuery.of(context).size.width;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width * 0.82,
        ),
        child: Material(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: textColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void show(BuildContext context, {
    required String message,
    bool isError = true,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismissed,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomSnackBar(
          message: message,
          isError: isError,
          duration: duration,
          onDismissed: onDismissed,
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onVisible: () {
          Future.delayed(duration, () {
            if (onDismissed != null) {
              onDismissed();
            }
          });
        },
      ),
    );
  }
}