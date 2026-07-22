import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:store/repositories/cart_repository.dart';
import 'package:store/repositories/product_repository.dart';
import 'package:store/models/products_model.dart';
import 'package:store/theme/app_colors.dart';
import 'package:intl/intl.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  String _searchQuery = '';
  final String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stock',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2F2F2F),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Handle add new product
                    },
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      size: 28,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Search bar
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFAEAEB2)),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Center(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF8E8E93),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedSearch01,
                          size: 24,
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Filter buttons
              Row(
                children: [
                  _buildFilterButton(
                    'Filter',
                    'filter',
                    _selectedFilter == 'filter',
                  ),
                  const SizedBox(width: 16),
                  _buildFilterButton(
                    'All stock',
                    'all',
                    _selectedFilter == 'all',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Products grid – rebuilds whenever the product list changes
              Expanded(
                child: Consumer<ProductRepository>(
                  builder: (context, productRepo, _) {
                    final products = productRepo.products;
                    final displayed = _searchQuery.trim().isEmpty
                        ? products
                        : products
                            .where(
                              (p) => p.name
                                  .toLowerCase()
                                  .contains(_searchQuery.trim().toLowerCase()),
                            )
                            .toList();
                    
                    if (productRepo.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (productRepo.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              productRepo.error!,
                              style: GoogleFonts.poppins(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (displayed.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2F2F2F),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'All Products',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF333333),
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: displayed.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(displayed[index]);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String value, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFAEAEB2)),
        borderRadius: BorderRadius.circular(99),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          HugeIcon(
            icon: value == 'filter'
                ? HugeIcons.strokeRoundedFilterHorizontal
                : HugeIcons.strokeRoundedFilterVertical,
            size: 16,
            color: const Color(0xFF8E8E93),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: const Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(StockItem product) {
    return GestureDetector(
      onTap: () {
        _showProductModal(product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      color: Colors.grey[200],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          child: Image.network(
                            product.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              );
                            },
                          ),
                        ),
                        if (product.status != StockStatus.normal)
                          Container(color: Colors.white.withValues(alpha: 0.4)),
                      ],
                    ),
                  ),
                ),
                // Product info
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF333333),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.status == StockStatus.outOfStock)
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    context.read<ProductRepository>().remove(product.id);
                                  },
                                  child: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedDelete04,
                                    size: 14,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    _showProductModal(product);
                                  },
                                  child: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedAdd01,
                                    size: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              '${product.quantity}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF333333),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Status badge
            if (product.status != StockStatus.normal)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: product.status == StockStatus.lowStock
                        ? const Color(0xFFFFD700)
                        : Colors.red,
                  ),
                  child: Text(
                    product.status == StockStatus.lowStock ? '⚠' : '●',
                    style: const TextStyle(fontSize: 8),
                  ),
                ),
              ),
            // Status label
            if (product.status != StockStatus.normal)
              Positioned(
                top: 6,
                left: 6,
                child: Text(
                  product.status == StockStatus.lowStock
                      ? 'Low on stock'
                      : 'Out of stock',
                  style: GoogleFonts.poppins(
                    fontSize: 6,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showProductModal(StockItem product) {
    final quantityController = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(product.image),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.7),
                          Colors.white,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Content
                  SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E0E0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 220),
                          // Product name and price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2F2F2F),
                                  ),
                                ),
                              ),
                              if (product.price != null)
                                Text(
                                  '₵${product.price!.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navigationActive,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Expiry date
                          if (product.expiryDate != null) ...[
                            Text(
                              'Expiry Date',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5E5E5E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat(
                                'MMM d, y',
                              ).format(product.expiryDate!),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF2F2F2F),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Description
                          if (product.description != null) ...[
                            Text(
                              'Description',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5E5E5E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              product.description!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                height: 1.5,
                                color: const Color(0xFF2F2F2F),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                           // Quantity input
                          Text(
                            'Quantity (max ${product.quantity})',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5E5E5E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _MaxValueFormatter(product.quantity),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Enter quantity',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF8E8E93),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.navigationActive,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2F2F2F),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    final qty =
                                        int.tryParse(quantityController.text) ??
                                        1;
                                    if (qty <= 0) return;
                                    final actualQty = qty > product.quantity ? product.quantity : qty;
                                    // ── Actually add to the cart ──
                                    context.read<CartRepository>().addItem(product, actualQty);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${product.name} ×$actualQty added to cart',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.navigationActive,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Add to Cart',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MaxValueFormatter extends TextInputFormatter {
  final int maxValue;
  _MaxValueFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final value = int.tryParse(newValue.text);
    if (value == null) return oldValue;
    if (value > maxValue) {
      return TextEditingValue(
        text: '$maxValue',
        selection: TextSelection.collapsed(offset: '$maxValue'.length),
      );
    }
    return newValue;
  }
}
