import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mobile_dapp/models/wallet_model.dart';
import 'package:mobile_dapp/widgets/custom_button.dart';
import 'package:mobile_dapp/widgets/wallet_card.dart';
import 'package:mobile_dapp/services/wallet_service.dart';

class WalletManagementSheet extends StatefulWidget {
  final List<WalletModel> wallets;
  final Function(WalletModel) onDeleteWallet;
  final Function(WalletModel) onSelectWallet;
  final Animation<double> fadeAnimation;
  final VoidCallback? onCreateWallet;

  const WalletManagementSheet({
    super.key,
    required this.wallets,
    required this.onDeleteWallet,
    required this.onSelectWallet,
    required this.fadeAnimation,
    this.onCreateWallet,
  });

  @override
  State<WalletManagementSheet> createState() => _WalletManagementSheetState();
}

class _WalletManagementSheetState extends State<WalletManagementSheet> {
  late List<WalletModel> _wallets;
  final WalletService _walletService = WalletService();
  final Map<String, bool> _loadingStates = {};
  final Map<String, String> _balanceStates = {};
  bool _isRefreshingAll = false;

  @override
  void initState() {
    super.initState();
    _wallets = widget.wallets;
    _refreshAllBalances();
  }

  @override
  void didUpdateWidget(WalletManagementSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallets != widget.wallets) {
      setState(() {
        _wallets = widget.wallets;
      });
      _refreshAllBalances();
    }
  }

  Future<void> _refreshBalance(String address) async {
    if (!mounted) return;
    setState(() {
      _loadingStates[address] = true;
    });

    try {
      final balance = await _walletService.getBalance(address);
      final formattedBalance = _walletService.formatBalance(balance);
      if (!mounted) return;
      setState(() {
        _balanceStates[address] = formattedBalance;
        _loadingStates[address] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _balanceStates[address] = '0';
        _loadingStates[address] = false;
      });
    }
  }

  Future<void> _refreshAllBalances() async {
    if (!mounted) return;
    setState(() {
      _isRefreshingAll = true;
    });

    for (final wallet in _wallets) {
      await _refreshBalance(wallet.address);
    }

    if (!mounted) return;
    setState(() {
      _isRefreshingAll = false;
    });
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, WalletModel wallet) async {
    HapticFeedback.mediumImpact();
    return showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Wallet'),
        content: const Text(
          'This action cannot be undone. This will permanently remove the wallet from your device.',
          textAlign: TextAlign.center,
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteWallet(wallet);
              setState(() {
                _wallets.removeWhere((w) => w.address == wallet.address);
                _balanceStates.remove(wallet.address);
                _loadingStates.remove(wallet.address);
              });
            },
            isDestructiveAction: true,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Wallets',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_wallets.length} wallet${_wallets.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: _isRefreshingAll
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onSurface,
                            ),
                          )
                        : Icon(Icons.refresh, color: colorScheme.onSurface),
                    onPressed: _isRefreshingAll ? null : _refreshAllBalances,
                    tooltip: 'Refresh all balances',
                  ),
                ],
              ),
            ),
            if (_wallets.isEmpty) ...[
              Expanded(
                child: FadeTransition(
                  opacity: widget.fadeAnimation,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.primaryContainer.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.wallet_outlined,
                            size: 64,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No wallets yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first wallet to get started',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (widget.onCreateWallet != null)
                          CustomButton(
                            onPressed: widget.onCreateWallet,
                            isLoading: false,
                            text: 'Create New Wallet',
                            icon: Icons.add_circle_outline,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: FadeTransition(
                  opacity: widget.fadeAnimation,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: _wallets.length * 280.0,
                      child: Stack(
                        children: _wallets.asMap().entries.map((entry) {
                          final index = entry.key;
                          final wallet = entry.value;
                          final isLoading =
                              _loadingStates[wallet.address] ?? false;
                          final balance = _balanceStates[wallet.address] ?? '0';

                          return Positioned(
                            top: index * 80.0,
                            left: 0,
                            right: 0,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context);
                                    widget.onSelectWallet(wallet);
                                  },
                                  child: WalletCard(
                                    balance: balance,
                                    isLoading: isLoading,
                                    onRefresh: () =>
                                        _refreshBalance(wallet.address),
                                    animation: widget.fadeAnimation,
                                    showNetwork: false,
                                    showLastUpdated: false,
                                    title: wallet.name.isNotEmpty
                                        ? wallet.name
                                        : 'Unnamed Wallet',
                                    bottomContent: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.account_balance_wallet,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                                .withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${wallet.address.substring(0, 7)}...${wallet.address.substring(wallet.address.length - 5)}',
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actionButton: IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                      onPressed: () => _showDeleteConfirmation(
                                          context, wallet),
                                      tooltip: 'Delete wallet',
                                      iconSize: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.onCreateWallet != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomButton(
                    onPressed: widget.onCreateWallet,
                    isLoading: false,
                    text: 'Create New Wallet',
                    icon: Icons.add_circle_outline,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
