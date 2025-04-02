import 'package:flutter/material.dart';
import 'screens/wallet_screen.dart';
import 'screens/wallet_details_screen.dart';
import 'utils/page_route.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet Balance Checker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return CustomPageRoute(child: const WalletScreen());
        }
        if (settings.name == '/wallet-details') {
          final args = settings.arguments as Map<String, dynamic>;
          return CustomPageRoute(
            child: WalletDetailsScreen(
              address: args['address'] as String,
              isNewWallet: args['isNewWallet'] as bool? ?? false,
              isOwnedWallet: args['isOwnedWallet'] as bool? ?? false,
            ),
          );
        }
        return null;
      },
    );
  }
}
