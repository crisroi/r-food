import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class CloudinaryService {
  static const String cloudName    = 'di037vgjc';
  static const String uploadPreset = 'r_foods_uploads';

  final CloudinaryPublic _cloudinary;

  CloudinaryService()
      : _cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

  /// Upload image bytes — works on web AND native.
  /// Always use this method; never pass File directly.
  Future<String> uploadImageFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: fileName,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      rethrow;
    }
  }

  /// Returns a resized / quality-adjusted Cloudinary URL without re-uploading.
  String getOptimizedUrl({
    required String imageUrl,
    int? width,
    int? height,
    String quality = 'auto',
  }) {
    final uri      = Uri.parse(imageUrl);
    final segments = uri.pathSegments;
    final idx      = segments.indexOf('upload');
    if (idx == -1) return imageUrl;

    final publicId   = segments.sublist(idx + 1).join('/');
    final transforms = [
      'q_$quality',
      if (width  != null) 'w_$width',
      if (height != null) 'h_$height',
      'c_fill',
    ].join(',');

    return 'https://res.cloudinary.com/$cloudName/image/upload/$transforms/$publicId';
  }
}

/// Folder constants
class CloudinaryFolders {
  static const String profilePictures   = 'profile_pictures';
  static const String menuItems         = 'menu_items';
  static const String idCards           = 'id_cards';
  static const String hostelAllocations = 'hostel_allocations';
}