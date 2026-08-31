import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/shop/create_account.dart';
import '../../theme/app_colors.dart';
import '../../widgets/account_cards.dart';
import '../auth/create_account.dart';

class AccountType extends StatefulWidget {
  const AccountType({super.key});

  @override
  State<AccountType> createState() => _AccountTypeState();
}

class _AccountTypeState extends State<AccountType> {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundColor,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose Account Type',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Set up your account by selecting the type that best describes you.',
              style: GoogleFonts.poppins(
                letterSpacing: 0.38,
                fontSize: 16,
                color: AppColors.labelPrimary,
              ),
            ),
            const SizedBox(height: 64),
            AccountCard(
              accountType: 'Customer',
              description:
                  'Shop for your favorite products and enjoy exclusive deals.',
              image: const Icon(
                Icons.shopping_bag_outlined,
                size: 138,
                color: AppColors.primary,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateAccount(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            AccountCard(
              accountType: 'Store Owner',
              description: 'List your products and manage your store.',
              image: const Icon(
                Icons.storefront_outlined,
                size: 138,
                color: AppColors.primary,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateShopAccount(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
