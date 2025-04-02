import 'package:flutter/material.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';

class WalletCard extends StatelessWidget {
  final String balance;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Animation<double> animation;
  final bool showNetwork;
  final bool showLastUpdated;
  final Widget? actionButton;
  final String title;
  final Widget? bottomContent;

  const WalletCard({
    super.key,
    required this.balance,
    required this.isLoading,
    required this.onRefresh,
    required this.animation,
    this.showNetwork = true,
    this.showLastUpdated = true,
    this.actionButton,
    this.title = 'Wallet Balance',
    this.bottomContent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: animation,
      child: CustomCard(
        usePrimaryGradient: true,
        height: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (showNetwork) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sepolia',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                if (actionButton != null)
                  actionButton!
                else
                  IconButton(
                    icon: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : Icon(Icons.refresh, color: colorScheme.onPrimaryContainer),
                    onPressed: onRefresh,
                    tooltip: 'Refresh balance',
                    iconSize: 24,
                  ),
              ],
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    )
                  else
                    Text(
                      balance,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'SepoliaETH',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (bottomContent != null)
              bottomContent!
            else if (showLastUpdated)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}