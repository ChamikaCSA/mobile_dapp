import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? leadingText;
  final IconData? leadingIcon;
  final String? trailingText;
  final String? trailingSubtext;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool usePrimaryGradient;

  const CustomListTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingText,
    this.leadingIcon,
    this.trailingText,
    this.trailingSubtext,
    this.onTap,
    this.backgroundColor,
    this.usePrimaryGradient = false,
  }) : assert(leadingText != null || leadingIcon != null);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (leadingIcon != null)
                  CircleAvatar(
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      leadingIcon,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  )
                else if (leadingText != null)
                  CircleAvatar(
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      leadingText![0].toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingText != null || trailingSubtext != null)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (trailingText != null)
                        Text(
                          trailingText!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      if (trailingSubtext != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          trailingSubtext!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}