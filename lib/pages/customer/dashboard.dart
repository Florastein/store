import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:store/pages/customer/checkout.dart';
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
    const CustomerOverview(),
    CheckoutScreen(),
    const StockPage(),
    const _PlaceholderPage(title: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _selectedNavIndex, children: _pages),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: _CustomerBottomNavBar(
                items: _navItems,
                selectedIndex: _selectedNavIndex,
                onSelected: (index) {
                  setState(() {
                    _selectedNavIndex = index;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 1.  CONSTANTS – all magic numbers in one place
// ---------------------------------------------------------------------
class _NavBarConstants {
  static const double height = 75.0;
  static const double padding = 6.0;
  static const double borderRadius = 56.0;
  static const double blurSigma = 18.0;
  static const double borderWidth = 1.2;
  static const double activeScale = 1.04;
  static const double activeSlide = -0.04;
  static const double iconSizeActive = 24.0;
  static const double iconSizeInactive = 24.0;
  static const double iconStrokeWidth = 1.8;
  static const double labelFontSize = 10.0;
  static const Duration indicatorDuration = Duration(milliseconds: 380);
  static const Duration itemDuration = Duration(milliseconds: 280);
  static const Duration textIconDuration = Duration(milliseconds: 260);
  static const Curve indicatorCurve = Curves.easeOutBack;
  static const Curve itemCurve = Curves.easeOutCubic;
}

// ---------------------------------------------------------------------
// 2.  ACTIVE INDICATOR (unchanged, but marked const)
// ---------------------------------------------------------------------
class _CustomerNavActiveIndicator extends StatelessWidget {
  const _CustomerNavActiveIndicator();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navigationActive.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 3.  SINGLE NAV ITEM – extracted for clarity and performance
// ---------------------------------------------------------------------
class _CustomerNavItemWidget extends StatelessWidget {
  const _CustomerNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _CustomerNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RepaintBoundary(
        child: Semantics(
          label: item.label,
          selected: isSelected,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(48),
              splashColor: AppColors.navigationActive.withValues(alpha: 0.08),
              highlightColor: Colors.white.withValues(alpha: 0.18),
              onTap: onTap,
              child: AnimatedScale(
                duration: _NavBarConstants.itemDuration,
                curve: _NavBarConstants.itemCurve,
                scale: isSelected ? _NavBarConstants.activeScale : 1.0,
                child: AnimatedSlide(
                  duration: _NavBarConstants.itemDuration,
                  curve: _NavBarConstants.itemCurve,
                  offset: isSelected
                      ? const Offset(0, _NavBarConstants.activeSlide)
                      : Offset.zero,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with animated switch
                      AnimatedSwitcher(
                        duration: _NavBarConstants.textIconDuration,
                        switchInCurve: _NavBarConstants.itemCurve,
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
                          key: ValueKey<String>(
                            'icon-${item.label}-$isSelected',
                          ),
                          icon: item.icon,
                          size: isSelected
                              ? _NavBarConstants.iconSizeActive
                              : _NavBarConstants.iconSizeInactive,
                          color: isSelected
                              ? AppColors.navigationActive
                              : const Color(0xFF4B5563),
                          strokeWidth: _NavBarConstants.iconStrokeWidth,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Label with animated style
                      AnimatedDefaultTextStyle(
                        duration: _NavBarConstants.textIconDuration,
                        curve: _NavBarConstants.itemCurve,
                        style: GoogleFonts.poppins(
                          fontSize: _NavBarConstants.labelFontSize,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
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
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 4.  MAIN NAV BAR WIDGET
// ---------------------------------------------------------------------
class _CustomerBottomNavBar extends StatelessWidget {
  const _CustomerBottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_CustomerNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_NavBarConstants.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _NavBarConstants.blurSigma,
          sigmaY: _NavBarConstants.blurSigma,
        ),
        child: Container(
          height: _NavBarConstants.height,
          padding: const EdgeInsets.all(_NavBarConstants.padding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(_NavBarConstants.borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.56),
              width: _NavBarConstants.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.26),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final activeItemWidth = constraints.maxWidth / items.length;

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: _NavBarConstants.indicatorDuration,
                    curve: _NavBarConstants.indicatorCurve,
                    left: activeItemWidth * selectedIndex,
                    top: 0,
                    bottom: 0,
                    width: activeItemWidth,
                    child: RepaintBoundary(
                      child: const _CustomerNavActiveIndicator(),
                    ),
                  ),
                  // Row of items – each wrapped in RepaintBoundary
                  Row(
                    children: items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _CustomerNavItemWidget(
                        item: item,
                        isSelected: selectedIndex == index,
                        onTap: () => onSelected(index),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 5.  NAV ITEM DATA CLASS (immutable)
// ---------------------------------------------------------------------
@immutable
class _CustomerNavItem {
  const _CustomerNavItem({required this.label, required this.icon});

  final String label;
  final List<List<dynamic>> icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CustomerNavItem &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          icon == other.icon;

  @override
  int get hashCode => Object.hash(label, icon);
}

// ---------------------------------------------------------------------
// 6.  (OPTIONAL) PLACEHOLDER PAGE – kept only for demo completeness
// ---------------------------------------------------------------------
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

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
