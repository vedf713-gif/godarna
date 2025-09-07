import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:godarna/utils/permissions.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  static const String _bucket = 'images';

  // Upload single image
  Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      // Require authenticated user to satisfy RLS insert policy
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول قبل رفع الصور');
      }
      // Compress image before upload (target ~ < 1.5MB, max dimension 1920)
      final File compressed = await compressImageIfNeeded(
        imageFile,
        maxSizeMB: 0.8,
        maxDimension: 1280,
        quality: 75,
      );
      // Use .jpg extension for compressed image
      final base = path.basenameWithoutExtension(compressed.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$base.jpg';
      final filePath = '$folder/$fileName';
      // Read compressed bytes to upload as binary with correct content type
      final bytes = await compressed.readAsBytes();
      await _supabase.storage.from('images').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final imageUrl = _supabase.storage.from('images').getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      dev.log('Error uploading image: $e', name: 'StorageService');
      // Optionally, rethrow or return null. We keep null to let UI handle gracefully
      return null;
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(
      List<File> imageFiles, String folder) async {
    final List<String> uploadedUrls = [];
    // Guard: must be authenticated once
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول قبل رفع الصور');
    }

    for (final imageFile in imageFiles) {
      final url = await uploadImage(imageFile, folder);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      // اطلب إذن الصور/الوسائط قبل الفتح
      final granted = await PermissionsHelper.requestMediaPermission();
      if (!granted) {
        return null;
      }
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      dev.log('Error picking image from gallery: $e', name: 'StorageService');
      return null;
    }
  }

  // Pick multiple images from gallery
  Future<List<File>> pickMultipleImagesFromGallery() async {
    try {
      // اطلب إذن الصور/الوسائط قبل الفتح
      final granted = await PermissionsHelper.requestMediaPermission();
      if (!granted) {
        return [];
      }
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      dev.log('Error picking multiple images: $e', name: 'StorageService');
      return [];
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      // اطلب إذن الكاميرا قبل الالتقاط
      final granted = await PermissionsHelper.requestCameraPermission();
      if (!granted) {
        return null;
      }
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      dev.log('Error picking image from camera: $e', name: 'StorageService');
      return null;
    }
  }

  // Delete image from storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract object path from public/signed URL
      final objectPath = _extractObjectPath(imageUrl);
      if (objectPath == null) {
        throw Exception('Invalid image URL');
      }
      await _supabase.storage.from('images').remove([objectPath]);
      return true;
    } catch (e) {
      dev.log('Error deleting image: $e', name: 'StorageService');
      return false;
    }
  }

  // Extract the object path inside the bucket from a Supabase URL
  // Examples:
  // https://xyz.supabase.co/storage/v1/object/public/images/properties/123/a.jpg -> properties/123/a.jpg
  // https://xyz.supabase.co/storage/v1/object/sign/images/avatars/u1.png?token=... -> avatars/u1.png
  String? _extractObjectPath(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // Find the index of the bucket id ('images') in the path
      final bucketIndex = segments.indexOf('images');
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return null;
      final objectSegments = segments.sublist(bucketIndex + 1);
      return objectSegments.join('/');
    } catch (_) {
      return null;
    }
  }

  // Get image size in MB
  double getImageSizeInMB(File imageFile) {
    final bytes = imageFile.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Compress image if needed using package:image
  // - Re-encodes to JPEG
  // - Resizes to fit within maxDimension (keeping aspect ratio)
  // - Iteratively reduces quality until under maxSizeMB (or min quality)
  Future<File> compressImageIfNeeded(
    File imageFile, {
    double maxSizeMB = 1.5,
    int maxDimension = 1920,
    int quality = 85,
  }) async {
    try {
      final currentSize = getImageSizeInMB(imageFile);
      if (currentSize <= maxSizeMB) {
        return imageFile;
      }

      final Uint8List inputBytes = await imageFile.readAsBytes();
      final img.Image? decoded = img.decodeImage(inputBytes);
      if (decoded == null) {
        // Fallback: return original if decode fails
        return imageFile;
      }

      // Resize if larger than maxDimension
      img.Image processed = decoded;
      final int maxSide =
          decoded.width > decoded.height ? decoded.width : decoded.height;
      if (maxSide > maxDimension) {
        processed = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxDimension : null,
          height: decoded.height > decoded.width ? maxDimension : null,
          interpolation: img.Interpolation.average,
        );
      }

      int q = quality;
      Uint8List encoded =
          Uint8List.fromList(img.encodeJpg(processed, quality: q));
      double sizeMB = encoded.lengthInBytes / (1024 * 1024);
      while (sizeMB > maxSizeMB && q > 40) {
        q -= 5;
        encoded = Uint8List.fromList(img.encodeJpg(processed, quality: q));
        sizeMB = encoded.lengthInBytes / (1024 * 1024);
      }

      final tempDir = Directory.systemTemp;
      final outFile = File(path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
      await outFile.writeAsBytes(encoded, flush: true);
      return outFile;
    } catch (e) {
      // On any failure, return original file to avoid blocking upload
      dev.log('Compression failed: $e', name: 'StorageService');
      return imageFile;
    }
  }

  // Upload property images
  Future<List<String>> uploadPropertyImages(
      List<File> imageFiles, String propertyId) async {
    final folder = 'properties/$propertyId';
    return await uploadImages(imageFiles, folder);
  }

  // Upload user avatar
  Future<String?> uploadUserAvatar(File imageFile, String userId) async {
    final folder = 'avatars/$userId';
    return await uploadImage(imageFile, folder);
  }

  // Get storage usage
  Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      // Get all files from the storage bucket
      final files = await _supabase.storage.from(_bucket).list();
      
      int totalUsedBytes = 0;
      for (final file in files) {
        if (file.metadata?['size'] != null) {
          totalUsedBytes += (file.metadata!['size'] as num).toInt();
        }
      }
      
      // Convert bytes to MB
      final usedMB = (totalUsedBytes / (1024 * 1024)).round();
      const totalMB = 1000; // 1GB limit
      final percentage = (usedMB / totalMB) * 100;
      
      return {
        'used': usedMB,
        'total': totalMB,
        'percentage': percentage.clamp(0.0, 100.0),
        'usedBytes': totalUsedBytes,
      };
    } catch (e) {
      dev.log('Error getting storage usage: $e', name: 'StorageService');
      return {
        'used': 0,
        'total': 1000,
        'percentage': 0.0,
        'usedBytes': 0,
      };
    }
  }

  // Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      dev.log('Cleaning up temporary files...', name: 'StorageService');
      
      // Get all files from storage
      final files = await _supabase.storage.from(_bucket).list();
      
      // Find files older than 7 days that might be orphaned
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final filesToDelete = <String>[];
      
      for (final file in files) {
        final createdAt = file.createdAt;
        if (createdAt != null) {
          final createdDate = DateTime.tryParse(createdAt.toString());
          if (createdDate != null && createdDate.isBefore(sevenDaysAgo)) {
            // Check if file is referenced in any property
            final isReferenced = await _isFileReferenced(file.name);
            if (!isReferenced) {
              filesToDelete.add(file.name);
            }
          }
        }
      }
      
      // Delete orphaned files
      if (filesToDelete.isNotEmpty) {
        await _supabase.storage.from(_bucket).remove(filesToDelete);
        dev.log('Cleaned up ${filesToDelete.length} orphaned files', name: 'StorageService');
      } else {
        dev.log('No temporary files to clean up', name: 'StorageService');
      }
    } catch (e) {
      dev.log('Error cleaning up temporary files: $e', name: 'StorageService');
    }
  }
  
  // Check if a file is referenced in any property
  Future<bool> _isFileReferenced(String fileName) async {
    try {
      final response = await _supabase
          .from('properties')
          .select('photos')
          .contains('photos', [fileName]);
      
      return response.isNotEmpty;
    } catch (e) {
      dev.log('Error checking file reference: $e', name: 'StorageService');
      // If we can't check, assume it's referenced to be safe
      return true;
    }
  }
}
