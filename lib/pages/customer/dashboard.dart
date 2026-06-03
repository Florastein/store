import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:store/pages/customer/overview.dart';
import 'package:store/pages/customer/stock.dart';
import 'package:store/theme/app_colors.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedNavIndex = 0;

  static const List<_CustomerNavItem> _navItems = [
    _CustomerNavItem(
      label: 'Overview',
      icon: HugeIcons.strokeRoundedDashboardCircle,
    ),
    _CustomerNavItem(
      label: 'Checkout',
      icon: HugeIcons.strokeRoundedShoppingBasketCheckOut01,
    ),
    _CustomerNavItem(label: 'Stock', icon: HugeIcons.strokeRoundedPackageAdd),
    _CustomerNavItem(
      label: 'Settings',
      icon: HugeIcons.strokeRoundedSettings01,
    ),
  ];

  late final List<Widget> _pages = [
    CustomerOverview(),
    const _PlaceholderPage(title: 'Checkout'),
    const StockPage(),
    const _PlaceholderPage(title: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: IndexedStack(index: _selectedNavIndex, children: _pages),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(56),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 88,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(56),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.78),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  return _buildNavItem(item: item, index: index);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required _CustomerNavItem item, required int index}) {
    final isSelected = _selectedNavIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(48),
          splashColor: AppColors.navigationActive.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.18),
          onTap: () {
            setState(() {
              _selectedNavIndex = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.56)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(48),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.86)
                    : Colors.transparent,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.navigationActive.withValues(
                          alpha: 0.12,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final scale = Tween<double>(
                      begin: 0.88,
                      end: 1.0,
                    ).animate(animation);

                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: scale, child: child),
                    );
                  },
                  child: HugeIcon(
                    key: ValueKey<String>('icon-$index-$isSelected'),
                    icon: item.icon,
                    size: isSelected ? 30 : 28,
                    color: isSelected
                        ? AppColors.navigationActive
                        : const Color(0xFF4B5563),
                    strokeWidth: 1.8,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.navigationActive
                        : const Color(0xFF4B5563),
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _CustomerNavItem {
  const _CustomerNavItem({required this.label, required this.icon});

  final String label;
  final List<List<dynamic>> icon;
}
