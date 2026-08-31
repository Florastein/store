import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/products_model.dart';

/// A product image that uses disk caching via cached_network_image.
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
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: product.image,
    key: ValueKey(product.image),
    width: width,
    height: height,
    fit: fit,
    placeholder: (context, url) => SizedBox(
      width: width,
      height: height,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ),
    errorWidget: (context, url, error) => _placeholder(),
    memCacheWidth: width?.toInt(),
    memCacheHeight: height?.toInt(),
    maxWidthDiskCache: 400,
    maxHeightDiskCache: 400,
  );

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: Colors.grey[200],
    alignment: Alignment.center,
    child: Icon(Icons.image_not_supported, size: iconSize),
  );
}
