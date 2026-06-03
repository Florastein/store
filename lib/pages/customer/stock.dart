import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:store/theme/app_colors.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  String _searchQuery = '';
  String _selectedFilter = 'all';

  final List<StockItem> _products = [
    StockItem(
      id: 1,
      name: 'KitKat',
      quantity: 80,
      image: 'https://via.placeholder.com/120?text=KitKat',
      status: StockStatus.normal,
    ),
    StockItem(
      id: 2,
      name: 'Lay\'s',
      quantity: 200,
      image: 'https://via.placeholder.com/120?text=Lays',
      status: StockStatus.normal,
    ),
    StockItem(
      id: 3,
      name: 'Pepsi',
      quantity: 6,
      image: 'https://via.placeholder.com/120?text=Pepsi',
      status: StockStatus.lowStock,
    ),
    StockItem(
      id: 4,
      name: 'Nutella',
      quantity: 0,
      image: 'https://via.placeholder.com/120?text=Nutella',
      status: StockStatus.outOfStock,
    ),
    StockItem(
      id: 5,
      name: 'Cheetos',
      quantity: 80,
      image: 'https://via.placeholder.com/120?text=Cheetos',
      status: StockStatus.normal,
    ),
    StockItem(
      id: 6,
      name: 'Oreo',
      quantity: 50,
      image: 'https://via.placeholder.com/120?text=Oreo',
      status: StockStatus.normal,
    ),
    StockItem(
      id: 7,
      name: 'Bottle Water',
      quantity: 100,
      image: 'https://via.placeholder.com/120?text=Water',
      status: StockStatus.normal,
    ),
    StockItem(
      id: 8,
      name: 'Tide plus',
      quantity: 30,
      image: 'https://via.placeholder.com/120?text=Tide',
      status: StockStatus.normal,
    ),
    StockItem(
      id: 9,
      name: 'Vanish gold',
      quantity: 19,
      image: 'https://via.placeholder.com/120?text=Vanish',
      status: StockStatus.normal,
    ),
  ];

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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  _buildFilterButton('Filter', 'filter', _selectedFilter == 'filter'),
                  const SizedBox(width: 16),
                  _buildFilterButton('All stock', 'all', _selectedFilter == 'all'),
                ],
              ),
              const SizedBox(height: 16),
              // Products grid
              Expanded(
                child: ListView(
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_products[index]);
                      },
                    ),
                  ],
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
    return Container(
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
                        Container(
                          color: Colors.white.withOpacity(0.4),
                        ),
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
                                  // Handle delete
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
                                  // Handle add
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }
}

enum StockStatus { normal, lowStock, outOfStock }

class StockItem {
  final int id;
  final String name;
  final int quantity;
  final String image;
  final StockStatus status;

  StockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.image,
    required this.status,
  });
}
