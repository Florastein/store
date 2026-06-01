import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/theme/app_colors.dart';
import 'package:store/widgets/acctount_cards.dart';

class AccountType extends StatefulWidget {
  const AccountType({super.key});

  @override
  State<AccountType> createState() => _AccountTypeState();
}

class _AccountTypeState extends State<AccountType> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Account Type',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your account by selecting the type that best describes you.',
                style: GoogleFonts.poppins(fontSize: 16, color: AppColors.gray),
              ),
              SizedBox(height: 24),
              AccountCard(
                accountType: 'Customer',
                description:
                    'Shop for your favorite products and enjoy exclusive deals.',
                image: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 138,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              AccountCard(
                accountType: 'Store Owner',
                description: 'List your products and manage your store.',
                image: const Icon(
                  Icons.storefront_outlined,
                  size: 138,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
