import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:store/repositories/cart_repository.dart';
import 'package:store/theme/app_colors.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Consumer<CartRepository>(
          builder: (context, cartRepo, _) {
            final cartItems = cartRepo.items;
            
            if (cartRepo.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (cartRepo.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      cartRepo.error!,
                      style: GoogleFonts.poppins(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2F2F2F)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: Color(0xFF2F2F2F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cart',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2F2F2F),
                        ),
                      ),
                      if (cartItems.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navigationActive,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${cartItems.length}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (cartItems.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            cartRepo.clear();
                          },
                          child: Text(
                            'Clear all',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Body ──────────────────────────────────────────────────
                if (cartItems.isEmpty)
                  _EmptyCartState()
                else
                  Expanded(
                    child: Column(
                      children: [
                        // Cart items list
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            itemCount: cartItems.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              return _CartItemCard(item: item);
                            },
                          ),
                        ),

                        // ── Order Summary ────────────────────────────────
                        _OrderSummary(items: cartItems),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────
class _EmptyCartState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/empty_cart.png',
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.shopping_cart_outlined,
                  size: 100,
                  color: Colors.grey,
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'No items in cart',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2F2F2F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products from the Stock tab',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// ── Single cart item card ─────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.product.image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2F2F2F),
                  ),
                ),
                if (item.product.price != null)
                  Text(
                    '₵${item.product.price!.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.navigationActive,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Quantity stepper
          Row(
            children: [
              _StepperButton(
                icon: Icons.remove,
                onTap: () {
                  context.read<CartRepository>().updateQuantity(
                    item.product.id,
                    item.quantity - 1,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2F2F2F),
                  ),
                ),
              ),
              _StepperButton(
                icon: Icons.add,
                onTap: () {
                  context.read<CartRepository>().updateQuantity(
                    item.product.id,
                    item.quantity + 1,
                  );
                },
              ),
            ],
          ),

          // Remove button
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.read<CartRepository>().removeItem(item.product.id),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small +/- button ─────────────────────────────────────────────────────────
class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.navigationActive.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.navigationActive),
      ),
    );
  }
}

// ── Order summary footer ──────────────────────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalPrice = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.product.price ?? 0.0) * item.quantity,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items ($totalItems)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF8E8E93),
                ),
              ),
              Text(
                '₵${totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2F2F2F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2F2F2F),
                ),
              ),
              Text(
                '₵${totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navigationActive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Order placed! Total: ₵${totalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(),
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
                context.read<CartRepository>().clear();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.navigationActive,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Place Order',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
