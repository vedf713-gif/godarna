import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/models/property_model.dart';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'dart:developer' as dev;

class PropertyService {
  static final PropertyService _instance = PropertyService._internal();
  factory PropertyService() => _instance;
  PropertyService._internal();
  
  static PropertyService get instance => _instance;
  
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucket = 'images';

  // Realtime subscription for properties
  RealtimeChannel? subscribeToProperties({
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    try {
      var channel = _supabase.channel('properties_realtime');
      
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'properties',
        callback: (payload) {
          dev.log('🔍 [Property] New property: ${payload.newRecord}', name: 'PropertyService');
          onInsert(payload.newRecord);
        },
      ).onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'properties',
        callback: (payload) {
          dev.log('🔍 [Property] Updated property: ${payload.newRecord}', name: 'PropertyService');
          onUpdate(payload.newRecord);
        },
      ).onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'properties',
        callback: (payload) {
          dev.log('🔍 [Property] Deleted property: ${payload.oldRecord}', name: 'PropertyService');
          onDelete(payload.oldRecord);
        },
      );

      return channel.subscribe((status, [ref]) {
        dev.log('🔍 [Property] Realtime status: $status', name: 'PropertyService');
      });
    } catch (e) {
      dev.log('subscribeToProperties error: $e', name: 'PropertyService');
      return null;
    }
  }

  // Get all properties
  Future<List<PropertyModel>> getProperties() async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PropertyModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get properties: $e');
    }
  }

  // Get property by ID
  Future<PropertyModel?> getPropertyById(String propertyId) async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .eq('id', propertyId)
          .single();

      return PropertyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get property: $e');
    }
  }

  // Get properties by host
  Future<List<PropertyModel>> getPropertiesByHost(String hostId) async {
    try {
      final response = await _supabase
          .from('properties')
          .select()
          .eq('host_id', hostId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PropertyModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get host properties: $e');
    }
  }

  // Add new property
  Future<PropertyModel?> addProperty(PropertyModel property) async {
    try {
      final propertyData = {
        'host_id': property.hostId,
        'title': property.title,
        'description': property.description,
        'property_type': property.propertyType,
        'price_per_night': property.pricePerNight,
        'price_per_month': property.pricePerMonth,
        'address': property.address,
        'region': property.region,
        'city': property.city,
        'area': property.area,
        'lat': property.latitude,
        'lng': property.longitude,
        'bedrooms': property.bedrooms,
        'bathrooms': property.bathrooms,
        'max_guests': property.maxGuests,
        'amenities': property.amenities,
        'photos': property.photos,
        'is_available': property.isAvailable,
        'is_verified': property.isVerified,
        'additional_info': property.additionalInfo,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('محاولة إضافة عقار بالبيانات: $propertyData');

      final response = await _supabase
          .from('properties')
          .insert(propertyData)
          .select()
          .single();

      debugPrint('تم إنشاء العقار بنجاح: $response');
      return PropertyModel.fromJson(response);
    } catch (e) {
      debugPrint('خطأ في إضافة العقار: $e');
      if (e is PostgrestException) {
        throw Exception('خطأ في قاعدة البيانات: ${e.message} (كود: ${e.code})');
      }
      throw Exception('فشل في إضافة العقار: $e');
    }
  }

  // Update property
  Future<PropertyModel?> updateProperty(PropertyModel property) async {
    try {
      final updateData = {
        'title': property.title,
        'description': property.description,
        'property_type': property.propertyType,
        'price_per_night': property.pricePerNight,
        'price_per_month': property.pricePerMonth,
        'address': property.address,
        'region': property.region,
        'city': property.city,
        'area': property.area,
        'lat': property.latitude,
        'lng': property.longitude,
        'bedrooms': property.bedrooms,
        'bathrooms': property.bathrooms,
        'max_guests': property.maxGuests,
        'amenities': property.amenities,
        'photos': property.photos,
        'is_available': property.isAvailable,
        'is_verified': property.isVerified,
        'additional_info': property.additionalInfo,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('properties')
          .update(updateData)
          .eq('id', property.id)
          .select()
          .single();

      return PropertyModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update property: $e');
    }
  }

  // Delete property
  Future<bool> deleteProperty(String propertyId) async {
    try {
      await _supabase
          .from('properties')
          .update({'is_active': false}).eq('id', propertyId);

      return true;
    } catch (e) {
      throw Exception('Failed to delete property: $e');
    }
  }

  // Search properties
  Future<List<PropertyModel>> searchProperties({
    String? query,
    String? city,
    String? propertyType,
    double? minPrice,
    double? maxPrice,
    int? maxGuests,
    DateTime? checkIn,
    DateTime? checkOut,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('properties')
          .select()
          .eq('is_active', true)
          .eq('is_available', true);

      if (city != null && city.isNotEmpty) {
        queryBuilder = queryBuilder.eq('city', city);
      }

      if (propertyType != null && propertyType.isNotEmpty) {
        queryBuilder = queryBuilder.eq('property_type', propertyType);
      }

      if (minPrice != null) {
        queryBuilder = queryBuilder.gte('price_per_night', minPrice);
      }

      if (maxPrice != null) {
        queryBuilder = queryBuilder.lte('price_per_night', maxPrice);
      }

      if (maxGuests != null) {
        queryBuilder = queryBuilder.gte('max_guests', maxGuests);
      }

      final response = await queryBuilder.order('created_at', ascending: false);

      var properties = (response as List)
          .map((json) => PropertyModel.fromJson(json))
          .toList();

      // Apply text search filter if query is provided
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        properties = properties.where((property) {
          return property.title.toLowerCase().contains(lowerQuery) ||
              property.description.toLowerCase().contains(lowerQuery) ||
              property.city.toLowerCase().contains(lowerQuery) ||
              property.area.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      return properties;
    } catch (e) {
      throw Exception('Failed to search properties: $e');
    }
  }

  // Get properties by location (nearby)
  Future<List<PropertyModel>> getPropertiesByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      // Simple distance calculation (in production, use PostGIS or similar)
      final response = await _supabase
          .from('properties')
          .select()
          .eq('is_active', true)
          .eq('is_available', true);

      final properties = (response as List)
          .map((json) => PropertyModel.fromJson(json))
          .toList();

      // Filter by distance
      return properties.where((property) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          property.latitude,
          property.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get properties by location: $e');
    }
  }

  // Update property availability
  Future<bool> updatePropertyAvailability(
      String propertyId, bool isAvailable) async {
    try {
      await _supabase.from('properties').update({
        'is_available': isAvailable,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', propertyId);

      return true;
    } catch (e) {
      throw Exception('Failed to update property availability: $e');
    }
  }

  // Update property photos
  Future<bool> updatePropertyPhotos(
      String propertyId, List<String> photos) async {
    try {
      await _supabase.from('properties').update({
        'photos': photos,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', propertyId);

      return true;
    } catch (e) {
      throw Exception('Failed to update property photos: $e');
    }
  }

  // ================= Storage: Upload/Delete Property Photos =================
  // Upload single photo bytes to Storage and return URL (public or signed)
  Future<String> uploadPropertyPhotoBytes({
    required String propertyId,
    required Uint8List bytes,
    String? contentType, // e.g. image/jpeg, image/png
    String? fileExt, // e.g. .jpg, .png
    bool signedUrl = false,
    Duration signedUrlExpiry = const Duration(hours: 6),
  }) async {
    try {
      // Always encode to JPEG after compression
      const ext = '.jpg';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_rand(1000, 999999)}$ext';
      final path = 'properties/$propertyId/$fileName';

      // Compress bytes if needed (target < ~0.8MB, max dimension 1280)
      final Uint8List compressed = await _compressBytesIfNeeded(
        bytes,
        maxSizeMB: 0.8,
        maxDimension: 1280,
        quality: 75,
      );

      await _supabase.storage.from(_bucket).uploadBinary(
            path,
            compressed,
            fileOptions: const FileOptions(
              // We re-encode to JPEG
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      if (signedUrl) {
        final seconds = signedUrlExpiry.inSeconds;
        final url = await _supabase.storage
            .from(_bucket)
            .createSignedUrl(path, seconds);
        return url;
      }
      return _supabase.storage.from(_bucket).getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Upload multiple photos and return list of URLs
  Future<List<String>> uploadMultiplePropertyPhotosBytes({
    required String propertyId,
    required List<Uint8List> files,
    String? contentType,
    String? fileExt,
    bool signedUrl = false,
    Duration signedUrlExpiry = const Duration(hours: 6),
  }) async {
    final urls = <String>[];
    for (final bytes in files) {
      final url = await uploadPropertyPhotoBytes(
        propertyId: propertyId,
        bytes: bytes,
        contentType: contentType,
        fileExt: fileExt,
        signedUrl: signedUrl,
        signedUrlExpiry: signedUrlExpiry,
      );
      urls.add(url);
    }
    return urls;
  }

  // Upload multiple photos with limited concurrency, retries, and progress callback
  Future<List<String>> uploadMultiplePropertyPhotosBytesConcurrent({
    required String propertyId,
    required List<Uint8List> files,
    int concurrency = 3,
    int maxRetries = 2,
    bool signedUrl = false,
    Duration signedUrlExpiry = const Duration(hours: 6),
    void Function(int completed, int total)? onProgress,
  }) async {
    if (files.isEmpty) return <String>[];
    final total = files.length;
    var completed = 0;
    final results = List<String?>.filled(total, null, growable: false);
    int nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final int index = nextIndex;
        if (index >= total) break;
        nextIndex = index + 1;

        int attempt = 0;
        while (true) {
          try {
            final url = await uploadPropertyPhotoBytes(
              propertyId: propertyId,
              bytes: files[index],
              signedUrl: signedUrl,
              signedUrlExpiry: signedUrlExpiry,
            );
            results[index] = url;
            completed += 1;
            onProgress?.call(completed, total);
            break;
          } catch (_) {
            if (attempt >= maxRetries) {
              rethrow;
            }
            attempt += 1;
            await Future.delayed(Duration(milliseconds: 300 * attempt));
          }
        }
      }
    }

    final workers = List.generate(concurrency, (_) => worker());
    await Future.wait(workers);
    return results.map((e) => e!).toList();
  }

  // Append uploaded photo URLs to property.photos
  Future<void> addPhotosToProperty(
      String propertyId, List<String> newPhotoUrls) async {
    final property = await getPropertyById(propertyId);
    final current = [...(property?.photos ?? <String>[])];
    current.addAll(newPhotoUrls);
    await updatePropertyPhotos(propertyId, current);
  }

  // Delete a photo from Storage by full path
  Future<void> deletePhotoByPath(String path) async {
    try {
      await _supabase.storage.from(_bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  // Delete by public URL (extract storage path)
  Future<void> deletePhotoByUrl(String url) async {
    final path = _extractPathFromUrl(url);
    if (path != null) {
      await deletePhotoByPath(path);
    } else {
      throw Exception('Invalid photo URL');
    }
  }

  // ========================= Helpers =========================
  // ignore: unused_element
  String? _extFromContentType(String? contentType) {
    switch (contentType) {
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
    }
    return null;
  }

  // ignore: unused_element
  String _guessContentTypeByExt(String ext) {
    switch (ext.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
    }
    return 'application/octet-stream';
  }

  // Compress raw image bytes if needed
  // - Decodes with package:image
  // - Resizes to fit within maxDimension preserving aspect ratio
  // - Re-encodes to JPEG with decreasing quality until under maxSizeMB (or min quality)
  Future<Uint8List> _compressBytesIfNeeded(
    Uint8List inputBytes, {
    double maxSizeMB = 1.5,
    int maxDimension = 1920,
    int quality = 85,
  }) async {
    try {
      final double currentSize = inputBytes.lengthInBytes / (1024 * 1024);
      if (currentSize <= maxSizeMB) {
        return inputBytes;
      }

      final img.Image? decoded = img.decodeImage(inputBytes);
      if (decoded == null) {
        return inputBytes; // fallback
      }

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
      while (sizeMB > maxSizeMB && q > 50) {
        q -= 5;
        encoded = Uint8List.fromList(img.encodeJpg(processed, quality: q));
        sizeMB = encoded.lengthInBytes / (1024 * 1024);
      }
      return encoded;
    } catch (_) {
      return inputBytes;
    }
  }

  String? _extractPathFromUrl(String url) {
    // Expected public URL example:
    // https://<project>.supabase.co/storage/v1/object/public/property-photos/properties/<propertyId>/<file>
    const marker = '/object/public/$_bucket/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    return url.substring(idx + marker.length);
  }

  int _rand(int min, int max) =>
      min + math.Random.secure().nextInt(max - min + 1);

  // Get property statistics
  Future<Map<String, dynamic>> getPropertyStats() async {
    try {
      final response = await _supabase
          .from('properties')
          .select('property_type, city, price_per_night, rating');

      final properties = response as List;

      final totalProperties = properties.length;
      final totalRevenue = properties.fold<double>(
        0.0,
        (sum, p) => sum + (p['price_per_night'] as num),
      );

      final propertyTypes = <String, int>{};
      final cities = <String, int>{};

      for (final property in properties) {
        final type = property['property_type'] as String;
        propertyTypes[type] = (propertyTypes[type] ?? 0) + 1;

        final city = property['city'] as String;
        cities[city] = (cities[city] ?? 0) + 1;
      }

      return {
        'total': totalProperties,
        'revenue': totalRevenue,
        'propertyTypes': propertyTypes,
        'cities': cities,
      };
    } catch (e) {
      throw Exception('Failed to get property stats: $e');
    }
  }

  // Private helper method to calculate distance between two points
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * math.pow(math.sin(dLon / 2), 2);
    final c = 2 * math.asin(math.min(1, math.sqrt(a)));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
