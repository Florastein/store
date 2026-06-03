/*import 'dart:io';

import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/transformation/delivery/delivery.dart';
import 'package:cloudinary_url_gen/transformation/delivery/delivery_actions.dart';
import 'package:cloudinary_url_gen/transformation/effect/effect.dart';
import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
class CloudinaryBackgroundRemovalService {
  final Cloudinary _cloudinary;

  CloudinaryBackgroundRemovalService({
    required String cloudName,
    required String apiKey,
    required String apiSecret,
  }) : _cloudinary = Cloudinary.fromStringUrl(
         'cloudinary://$apiKey:$apiSecret@$cloudName',
       );

  /// Uploads image + returns transformed transparent PNG URL
  Future<String> uploadAndRemoveBackground(File file) async {
    try {
      // 1. Upload original image
      final uploadResponse = await _cloudinary.uploader().upload(
        file,
        params: UploadParams(
          resourceType: CloudinaryResourceType.image,
          folder: 'background_removed',
          overwrite: true,
        ),
      );

      final publicId = uploadResponse.publicId;

      // 2. Build transformation URL (background removal + PNG output)
      final url = _cloudinary
          .image(publicId)
          .transformation(
            Transformation()
                // AI background removal (Cloudinary feature)
                .effect(Effect.backgroundRemoval())
                // Ensure PNG output (supports transparency)
                .delivery(Delivery.format("PNG")),
          )
          .toString();

      return url;
    } catch (e) {
      throw Exception('Cloudinary upload/background removal failed: $e');
    }
  }
}*/
