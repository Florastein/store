import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store/models/products_model.dart';
import 'package:store/repositories/product_repository.dart';

/// A product image that immediately reflects image changes in ProductRepository.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 24,
  });

  final StockItem product;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<ProductRepository>();
    final currentProduct = repository.findById(product.id) ?? product;
    final bytes = repository.imageBytesFor(
      currentProduct.id,
      currentProduct.image,
    );

    if (bytes != null) {
      return Image.memory(
        bytes,
        key: ValueKey('memory-${currentProduct.id}-${currentProduct.image}'),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return Image.network(
      currentProduct.image,
      key: ValueKey(currentProduct.image),
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: Colors.grey[200],
    alignment: Alignment.center,
    child: Icon(Icons.image_not_supported, size: iconSize),
  );
}
