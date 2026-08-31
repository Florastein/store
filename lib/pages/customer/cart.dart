import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store/providers/repositories.dart';
import 'package:store/repositories/interfaces/cart_repository.dart';
import 'package:store/repositories/interfaces/product_repository.dart';
import 'package:store/services/receipt_service.dart';
import 'package:store/theme/app_colors.dart';
import 'package:store/widgets/product_image.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartRepositoryNotifierProvider);
    final productRepo = ref.read(productRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: cartAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  style: GoogleFonts.poppins(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          data: (cartRepo) {
            final cartItems = cartRepo.items;

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
                              return _CartItemCard(
                                item: item,
                                productRepo: productRepo,
                              );
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
  Widget build(BuildContext context) => Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/empty_cart.svg',
              height: 180,
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

// ── Single cart item card ─────────────────────────────────────────────────────
class _CartItemCard extends ConsumerWidget {
  const _CartItemCard({
    required this.item,
    required this.productRepo,
  });

  final CartItem item;
  final ProductRepository productRepo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStock =
        productRepo.findById(item.product.id)?.quantity ?? item.product.quantity;
    final atMax = item.quantity >= currentStock;

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
            child: ProductImage(product: item.product, width: 60, height: 60),
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
                  ref.read(cartRepositoryProvider).updateQuantity(
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
                enabled: !atMax,
                onTap: () {
                  ref.read(cartRepositoryProvider).updateQuantity(
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
            onTap: () =>
                ref.read(cartRepositoryProvider).removeItem(item.product.id),
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
  const _StepperButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.navigationActive.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.navigationActive : Colors.grey,
        ),
      ),
    );
}

// ── Customer info field ───────────────────────────────────────────────────────
class _CustomerField extends StatelessWidget {
  const _CustomerField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2F2F2F),
          ),
        ),
        SizedBox(
          width: 180,
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              hintText: '001',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFB0B0B0),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.navigationActive,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
}

class _OrderSummary extends ConsumerStatefulWidget {
  const _OrderSummary({required this.items});

  final List<CartItem> items;

  @override
  ConsumerState<_OrderSummary> createState() => _OrderSummaryState();
}

class _OrderSummaryState extends ConsumerState<_OrderSummary> {
  bool _isActive = false;
  final TextEditingController _customerIdController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _customerIdController.addListener(() {
      setState(() {
        _isActive = _customerIdController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        children: [
          _CustomerField(
            label: 'Customer ID',
            controller: _customerIdController,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isActive ? _showReceipt : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isActive ? AppColors.labelPrimary : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Checkout',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

  Future<void> _showReceipt() async {
    final prefs = await SharedPreferences.getInstance();
    final shopName = prefs.getString('shop_name') ?? '';
    final customerName = prefs.getString('customer_name') ?? '';
    if (!mounted) {
      return;
    }
    final customerId = _customerIdController.text.trim();
    final totalPrice = widget.items.fold<double>(
      0,
      (sum, item) => sum + (item.product.price ?? 0.0) * item.quantity,
    );
    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')} - ${now.month.toString().padLeft(2, '0')} - ${now.year}   '
        '${now.hour.toString().padLeft(2, '0')} : ${now.minute.toString().padLeft(2, '0')}';
    final receiptNo =
        'RCP-${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.millisecondsSinceEpoch}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Receipt',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  shopName.isNotEmpty ? shopName : '...',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer Name',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customerName,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Receipt No.',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    receiptNo,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),
                          const _DashedLine(),

                          const SizedBox(height: 32),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ITEMS',
                                style: GoogleFonts.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                'Price',
                                style: GoogleFonts.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),

                          const _DashedLine(),

                          const SizedBox(height: 12),

                          ...widget.items.map(
                            (item) => _ReceiptItem(
                              name: item.product.name,
                              price: item.product.price ?? 0.0,
                              qty: item.quantity,
                            ),
                          ),

                          const SizedBox(height: 40),
                          const _DashedLine(),

                          const SizedBox(height: 8),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: GoogleFonts.dmSans(fontSize: 18),
                                  ),
                                  Text(
                                    '₵ ${totalPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'DATE & TIME',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'store',
                                    style: GoogleFonts.poppins(
                                      fontSize: 164,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => _shareReceipt(
                                    shopName: shopName,
                                    customerName: customerName,
                                    customerId: customerId,
                                    totalPrice: totalPrice,
                                    formattedDate: formattedDate,
                                    receiptNo: receiptNo,
                                    items: widget.items,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.42,
                                    decoration: BoxDecoration(
                                      color: AppColors.labelPrimary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Share',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.42,
                                    decoration: BoxDecoration(
                                      color: AppColors.labelPrimary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Close',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
    );
  }

  Future<void> _shareReceipt({
    required String shopName,
    required String customerName,
    required String customerId,
    required double totalPrice,
    required String formattedDate,
    required String receiptNo,
    required List<CartItem> items,
  }) async {
    final receiptService = ReceiptService();
    await receiptService.generateAndShareReceipt(
      shopName: shopName,
      customerName: customerName,
      customerId: customerId,
      totalPrice: totalPrice,
      formattedDate: formattedDate,
      receiptNo: receiptNo,
      items: items,
    );
  }
}

class _ReceiptItem extends StatelessWidget {
  const _ReceiptItem({
    required this.name,
    required this.price,
    required this.qty,
  });

  final String name;
  final double price;
  final int qty;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: .min,
            children: [
              Text(name, style: GoogleFonts.dmSans(fontSize: 14)),
              const SizedBox(width: 3),
              Text(
                'x$qty',
                style: GoogleFonts.dmSans(color: AppColors.gray, fontSize: 10),
              ),
            ],
          ),
          Text(
            '₵ ${(price * qty).toStringAsFixed(2)}',
            style: GoogleFonts.dmSans(fontSize: 14),
          ),
        ],
      ),
    );
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) => Row(
      children: List.generate(
        40,
        (_) => Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.only(right: 6),
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
}
