import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:store/pages/customer/notification_page.dart';
import 'package:store/repositories/product_repository.dart';
import 'package:store/models/products_model.dart';
import 'package:store/theme/app_colors.dart';

class CustomerOverview extends StatefulWidget {
  const CustomerOverview({super.key});

  @override
  State<CustomerOverview> createState() => _CustomerOverviewState();
}

class _CustomerOverviewState extends State<CustomerOverview> {
  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = context.watch<ProductRepository>();
    final products = productRepo.products;

    final totalProducts = products.length;
    final lowStockCount = products
        .where(
          (p) =>
              p.status == StockStatus.lowStock ||
              p.status == StockStatus.outOfStock,
        )
        .length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.26,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${getGreeting()}, ',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.labelPrimary,
                          ),
                        ),
                        Text(
                          'Davv',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.navigationActive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerNotificationPage(),
                      ),
                    );
                  },
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification01,
                    size: 30,
                    color: Colors.black,
                    strokeWidth: 1.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _statCard(title: 'Today Sales', value: '₵0.00'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(title: 'Orders', value: '0'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _statCard(title: 'Products', value: '$totalProducts'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(title: 'Low Stock', value: '$lowStockCount'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'No recent activity',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
