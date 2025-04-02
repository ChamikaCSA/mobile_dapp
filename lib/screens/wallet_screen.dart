import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_dapp/services/wallet_service.dart';
import 'package:mobile_dapp/models/wallet_model.dart';
import 'package:mobile_dapp/widgets/custom_app_bar.dart';
import 'package:mobile_dapp/widgets/custom_text_field.dart';
import 'package:mobile_dapp/widgets/custom_button.dart';
import 'package:mobile_dapp/widgets/wallet_management_sheet.dart';
import 'package:mobile_dapp/utils/clipboard_utils.dart';
import 'package:mobile_dapp/widgets/custom_snackbar.dart';
import 'package:mobile_dapp/widgets/custom_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with TickerProviderStateMixin {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mnemonicController = TextEditingController();
  final WalletService _walletService = WalletService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  late TabController _importTabController;
  bool _isWalletAddressValid = false;
  bool _isPrivateKeyValid = false;
  bool _isMnemonicValid = false;
  List<WalletModel> _wallets = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _tabController = TabController(length: 3, vsync: this);
    _importTabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _importTabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _addressController.addListener(_validateWalletAddress);
    _privateKeyController.addListener(_validatePrivateKey);
    _mnemonicController.addListener(_validateMnemonic);
    _nameController.addListener(() {
      setState(() {});
    });
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletService.getWallets();
      setState(() {
        _wallets = wallets;
      });
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteWallet(WalletModel wallet) async {
    try {
      await _walletService.deleteWallet(wallet.address);
      await _loadWallets();
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  void _showWalletManagementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WalletManagementSheet(
        wallets: _wallets,
        onDeleteWallet: _deleteWallet,
        onSelectWallet: (wallet) {
          Navigator.pushNamed(
            context,
            '/wallet-details',
            arguments: {
              'address': wallet.address,
              'isNewWallet': false,
              'isOwnedWallet': true,
            },
          );
        },
        fadeAnimation: _fadeAnimation,
      ),
    );
  }

  void _validateWalletAddress() {
    final isValid =
        _walletService.isValidAddress(_addressController.text.trim());
    if (isValid != _isWalletAddressValid) {
      setState(() {
        _isWalletAddressValid = isValid;
      });
    }
  }

  void _validatePrivateKey() {
    final isValid =
        _walletService.isValidPrivateKey(_privateKeyController.text.trim());
    if (isValid != _isPrivateKeyValid) {
      setState(() {
        _isPrivateKeyValid = isValid;
      });
    }
  }

  void _validateMnemonic() {
    final isValid =
        _walletService.isValidMnemonic(_mnemonicController.text.trim());
    if (isValid != _isMnemonicValid) {
      setState(() {
        _isMnemonicValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _addressController.removeListener(_validateWalletAddress);
    _privateKeyController.removeListener(_validatePrivateKey);
    _mnemonicController.removeListener(_validateMnemonic);
    _addressController.dispose();
    _privateKeyController.dispose();
    _mnemonicController.dispose();
    _nameController.dispose();
    _walletService.dispose();
    _animationController.dispose();
    _tabController.dispose();
    _importTabController.dispose();
    super.dispose();
  }

  Future<void> _getBalance() async {
    final address = _addressController.text.trim();

    if (!_isWalletAddressValid) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Invalid wallet address',
          isError: true,
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      setState(() {
        _isLoading = false;
        _addressController.clear();
        _privateKeyController.clear();
      });
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/wallet-details',
          arguments: {
            'address': address,
            'isNewWallet': false,
            'isOwnedWallet': false,
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _importWallet() async {
    final privateKey = _privateKeyController.text.trim();
    final name = _nameController.text.trim();

    if (!_isPrivateKeyValid) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Invalid private key',
          isError: true,
        );
      }
      return;
    }

    if (name.isEmpty) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Please enter a wallet name',
          isError: true,
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final wallet = await _walletService.importWallet(privateKey, name);
      await _loadWallets();

      setState(() {
        _isLoading = false;
        _addressController.clear();
        _privateKeyController.clear();
        _nameController.clear();
      });

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/wallet-details',
          arguments: {
            'address': wallet.address,
            'isNewWallet': false,
            'isOwnedWallet': true,
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _createWallet() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Please enter a wallet name',
          isError: true,
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final wallet = await _walletService.createWallet(name);
      await _loadWallets();

      setState(() {
        _isLoading = false;
        _nameController.clear();
      });

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/wallet-details',
          arguments: {
            'address': wallet.address,
            'isNewWallet': true,
            'isOwnedWallet': true,
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _importWalletFromMnemonic() async {
    final mnemonic = _mnemonicController.text.trim();
    final name = _nameController.text.trim();

    if (!_isMnemonicValid) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Invalid mnemonic phrase',
          isError: true,
        );
      }
      return;
    }

    if (name.isEmpty) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Please enter a wallet name',
          isError: true,
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final wallet =
          await _walletService.importWalletFromMnemonic(mnemonic, name);
      await _loadWallets();

      setState(() {
        _isLoading = false;
        _mnemonicController.clear();
        _nameController.clear();
      });

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/wallet-details',
          arguments: {
            'address': wallet.address,
            'isNewWallet': false,
            'isOwnedWallet': true,
          },
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final text = await ClipboardUtils.pasteFromClipboard();
    if (text != null) {
      _addressController.text = text;
    }
  }

  Future<void> _pastePrivateKeyFromClipboard() async {
    final text = await ClipboardUtils.pasteFromClipboard();
    if (text != null) {
      _privateKeyController.text = text;
    }
  }

  Future<void> _pasteMnemonicFromClipboard() async {
    final text = await ClipboardUtils.pasteFromClipboard();
    if (text != null) {
      _mnemonicController.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CustomAppBar(
                title: 'Wallet',
                icon: Icons.account_balance_wallet,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              TabBar(
                                controller: _tabController,
                                onTap: (index) {
                                  setState(() {});
                                },
                                labelColor: colorScheme.primary,
                                unselectedLabelColor:
                                    colorScheme.onSurfaceVariant,
                                indicatorColor: colorScheme.primary,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorWeight: 3,
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                tabs: const [
                                  Tab(text: 'Check Balance'),
                                  Tab(text: 'Import Wallet'),
                                  Tab(text: 'Create Wallet'),
                                ],
                              ),
                              SizedBox(
                                height: 361,
                                child: TabBarView(
                                  controller: _tabController,
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: _buildCheckBalanceTab(colorScheme),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: _buildImportWalletTab(colorScheme),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: _buildCreateWalletTab(colorScheme),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _showWalletManagementSheet,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.primaryContainer,
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Wallets',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                          Text(
                            '${_wallets.length} wallet${_wallets.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckBalanceTab(ColorScheme colorScheme) {
    return CustomCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomTextField(
            controller: _addressController,
            label: 'Wallet Address',
            hint: 'Enter wallet address',
            suffixIcon: Icons.paste,
            onSuffixIconPressed: _pasteFromClipboard,
            isValid: _isWalletAddressValid,
          ),
          CustomButton(
            onPressed:
                _isLoading || !_isWalletAddressValid ? null : _getBalance,
            isLoading: _isLoading,
            text: 'Check Balance',
            icon: CupertinoIcons.money_dollar_circle_fill,
          ),
        ],
      ),
    );
  }

  Widget _buildImportWalletTab(ColorScheme colorScheme) {
    return CustomCard(
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Wallet Name',
                  hint: 'Enter a name for your wallet',
                  isValid: _nameController.text.isNotEmpty,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _importTabController,
                        labelColor: colorScheme.primary,
                        unselectedLabelColor: colorScheme.onSurfaceVariant,
                        indicatorColor: colorScheme.primary,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'Private Key'),
                          Tab(text: 'Mnemonic'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _importTabController,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _privateKeyController,
                        label: 'Private Key',
                        hint: 'Enter your private key',
                        suffixIcon: Icons.paste,
                        onSuffixIconPressed: _pastePrivateKeyFromClipboard,
                        isPassword: true,
                        isValid: _isPrivateKeyValid,
                      ),
                      const Spacer(),
                      CustomButton(
                        onPressed: _isLoading ||
                                !_isPrivateKeyValid ||
                                _nameController.text.trim().isEmpty
                            ? null
                            : _importWallet,
                        isLoading: _isLoading,
                        text: 'Import Wallet',
                        icon: Icons.file_upload,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _mnemonicController,
                        label: 'Mnemonic Phrase',
                        hint: 'Enter your mnemonic phrase',
                        suffixIcon: Icons.paste,
                        onSuffixIconPressed: _pasteMnemonicFromClipboard,
                        maxLines: 3,
                        isValid: _isMnemonicValid,
                      ),
                      const Spacer(),
                      CustomButton(
                        onPressed: _isLoading ||
                                !_isMnemonicValid ||
                                _nameController.text.trim().isEmpty
                            ? null
                            : _importWalletFromMnemonic,
                        isLoading: _isLoading,
                        text: 'Import Wallet',
                        icon: Icons.file_upload,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateWalletTab(ColorScheme colorScheme) {
    return CustomCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Wallet Name',
            hint: 'Enter a name for your wallet',
            isValid: _nameController.text.isNotEmpty,
          ),
          CustomButton(
            onPressed: _isLoading || _nameController.text.trim().isEmpty
                ? null
                : _createWallet,
            isLoading: _isLoading,
            text: 'Create Wallet',
            icon: Icons.add_circle,
          ),
        ],
      ),
    );
  }
}
