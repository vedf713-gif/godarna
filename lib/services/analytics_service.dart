import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get user properties count
      final propertiesResponse =
          await _supabase.from('properties').select('id').eq('host_id', userId);

      // Get user bookings count
      final bookingsResponse =
          await _supabase.from('bookings').select('id').eq('tenant_id', userId);

      // Get total earnings (for hosts)
      final earningsResponse = await _supabase
          .from('bookings')
          .select('total_price')
          .eq('host_id', userId)
          .eq('status', 'completed');

      double totalEarnings = 0;
      for (final booking in earningsResponse) {
        totalEarnings += (booking['total_price'] ?? 0).toDouble();
      }

      return {
        'propertiesCount': (propertiesResponse as List).length,
        'bookingsCount': (bookingsResponse as List).length,
        'totalEarnings': totalEarnings,
        'averageRating': await _getUserAverageRating(userId),
      };
    } catch (e) {
      dev.log('Error getting user stats: $e', name: 'AnalyticsService');
      return {
        'propertiesCount': 0,
        'bookingsCount': 0,
        'totalEarnings': 0.0,
        'averageRating': 0.0,
      };
    }
  }

  // Get booking status counts for last N days
  Future<Map<String, int>> getBookingStatusCounts(int days) async {
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1));
      final to = DateTime(now.year, now.month, now.day + 1);

      final response = await _supabase
          .from('bookings')
          .select('status')
          .gte('created_at', from.toIso8601String())
          .lt('created_at', to.toIso8601String());

      final Map<String, int> counts = {};
      for (final row in response as List) {
        final status = (row['status'] ?? 'unknown').toString();
        counts[status] = (counts[status] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      dev.log('Error getting booking status counts: $e',
          name: 'AnalyticsService');
      return {};
    }
  }

  // Get revenue trends (completed bookings) per day
  Future<List<Map<String, dynamic>>> getRevenueTrends(int days) async {
    try {
      final List<Map<String, dynamic>> trends = [];
      final now = DateTime.now();

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final nextDate = date.add(const Duration(days: 1));

        final response = await _supabase
            .from('bookings')
            .select('total_price')
            .eq('status', 'completed')
            .gte('start_date',
                DateTime(date.year, date.month, date.day).toIso8601String())
            .lt(
                'start_date',
                DateTime(nextDate.year, nextDate.month, nextDate.day)
                    .toIso8601String());

        double total = 0;
        for (final row in response) {
          total += (row['total_price'] ?? 0).toDouble();
        }

        trends.add({
          'date': DateTime(date.year, date.month, date.day)
              .toIso8601String()
              .split('T')[0],
          'revenue': total,
        });
      }

      return trends.reversed.toList();
    } catch (e) {
      dev.log('Error getting revenue trends: $e', name: 'AnalyticsService');
      return [];
    }
  }

  // Get property statistics
  Future<Map<String, dynamic>> getPropertyStats(String propertyId) async {
    try {
      // Get bookings count
      final bookingsResponse = await _supabase
          .from('bookings')
          .select('id')
          .eq('property_id', propertyId);

      // Get total revenue
      final revenueResponse = await _supabase
          .from('bookings')
          .select('total_price')
          .eq('property_id', propertyId)
          .eq('status', 'completed');

      double totalRevenue = 0;
      for (final booking in revenueResponse) {
        totalRevenue += (booking['total_price'] ?? 0).toDouble();
      }

      // Get occupancy rate
      final occupancyRate = await _calculateOccupancyRate(propertyId);

      return {
        'bookingsCount': (bookingsResponse as List).length,
        'totalRevenue': totalRevenue,
        'occupancyRate': occupancyRate,
        'averageRating': await _getPropertyAverageRating(propertyId),
      };
    } catch (e) {
      dev.log('Error getting property stats: $e', name: 'AnalyticsService');
      return {
        'bookingsCount': 0,
        'totalRevenue': 0.0,
        'occupancyRate': 0.0,
        'averageRating': 0.0,
      };
    }
  }

  // Get platform statistics (for admins)
  Future<Map<String, dynamic>> getPlatformStats() async {
    try {
      // Get total users
      final usersResponse = await _supabase.from('users').select('id');

      // Get total properties
      final propertiesResponse =
          await _supabase.from('properties').select('id');

      // Get total bookings
      final bookingsResponse = await _supabase.from('bookings').select('id');

      // Get total revenue
      final revenueResponse = await _supabase
          .from('bookings')
          .select('total_price')
          .eq('status', 'completed');

      double totalRevenue = 0;
      for (final booking in revenueResponse) {
        totalRevenue += (booking['total_price'] ?? 0).toDouble();
      }

      // Get popular cities
      final popularCities = await getPopularCities();

      return {
        'totalUsers': (usersResponse as List).length,
        'totalProperties': (propertiesResponse as List).length,
        'totalBookings': (bookingsResponse as List).length,
        'totalRevenue': totalRevenue,
        'popularCities': popularCities,
        'averageRating': await _getPlatformAverageRating(),
      };
    } catch (e) {
      dev.log('Error getting platform stats: $e', name: 'AnalyticsService');
      return {
        'totalUsers': 0,
        'totalProperties': 0,
        'totalBookings': 0,
        'totalRevenue': 0.0,
        'popularCities': [],
        'averageRating': 0.0,
      };
    }
  }

  // Get monthly revenue for a property
  Future<List<Map<String, dynamic>>> getMonthlyRevenue(
      String propertyId, int months) async {
    try {
      final List<Map<String, dynamic>> monthlyData = [];
      final now = DateTime.now();

      for (int i = 0; i < months; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(now.year, now.month - i + 1, 1);

        final response = await _supabase
            .from('bookings')
            .select('total_price')
            .eq('property_id', propertyId)
            .eq('status', 'completed')
            .gte('start_date', month.toIso8601String())
            .lt('start_date', nextMonth.toIso8601String());

        double monthlyRevenue = 0;
        for (final booking in response) {
          monthlyRevenue += (booking['total_price'] ?? 0).toDouble();
        }

        monthlyData.add({
          'month': month.month,
          'year': month.year,
          'revenue': monthlyRevenue,
        });
      }

      return monthlyData.reversed.toList();
    } catch (e) {
      dev.log('Error getting monthly revenue: $e', name: 'AnalyticsService');
      return [];
    }
  }

  // Get popular property types
  Future<List<Map<String, dynamic>>> getPopularPropertyTypes() async {
    try {
      final response = await _supabase
          .from('properties')
          .select('property_type')
          .eq('is_active', true);

      final Map<String, int> typeCounts = {};

      for (final property in response) {
        final type = property['property_type'] ?? 'unknown';
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> popularTypes = [];
      final int total = (response as List).length;
      typeCounts.forEach((type, count) {
        popularTypes.add({
          'type': type,
          'count': count,
          'percentage': total == 0 ? 0.0 : (count / total) * 100,
        });
      });

      popularTypes.sort((a, b) => b['count'].compareTo(a['count']));
      return popularTypes;
    } catch (e) {
      dev.log('Error getting popular property types: $e',
          name: 'AnalyticsService');
      return [];
    }
  }

  // Get booking trends
  Future<List<Map<String, dynamic>>> getBookingTrends(int days) async {
    try {
      final List<Map<String, dynamic>> trends = [];
      final now = DateTime.now();

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final nextDate = date.add(const Duration(days: 1));

        final response = await _supabase
            .from('bookings')
            .select('id')
            .gte('created_at', date.toIso8601String())
            .lt('created_at', nextDate.toIso8601String());

        trends.add({
          'date': date.toIso8601String().split('T')[0],
          'bookings': (response as List).length,
        });
      }

      return trends.reversed.toList();
    } catch (e) {
      dev.log('Error getting booking trends: $e', name: 'AnalyticsService');
      return [];
    }
  }

  // Helper methods
  Future<double> _getUserAverageRating(String userId) async {
    try {
      final response = await _supabase
          .from('properties')
          .select('rating')
          .eq('host_id', userId)
          .not('rating', 'eq', 0);

      if (response.isEmpty) return 0.0;

      double totalRating = 0;
      for (final property in response) {
        totalRating += (property['rating'] ?? 0).toDouble();
      }

      return totalRating / response.length;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getPropertyAverageRating(String propertyId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('rating')
          .eq('property_id', propertyId)
          .not('rating', 'is', null);

      if (response.isEmpty) return 0.0;

      double totalRating = 0;
      for (final booking in response) {
        totalRating += (booking['rating'] ?? 0).toDouble();
      }

      return totalRating / response.length;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getPlatformAverageRating() async {
    try {
      final response = await _supabase
          .from('properties')
          .select('rating')
          .not('rating', 'eq', 0);

      if (response.isEmpty) return 0.0;

      double totalRating = 0;
      for (final property in response) {
        totalRating += (property['rating'] ?? 0).toDouble();
      }

      return totalRating / response.length;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _calculateOccupancyRate(String propertyId) async {
    try {
      // Get completed bookings for the last 12 months
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      final response = await _supabase
          .from('bookings')
          .select('start_date, end_date')
          .eq('property_id', propertyId)
          .eq('status', 'completed')
          .gte('start_date', oneYearAgo.toIso8601String());

      if (response.isEmpty) return 0.0;

      // Calculate total occupied nights
      int totalOccupiedNights = 0;
      for (final booking in response) {
        final checkIn = DateTime.parse(booking['start_date']);
        final checkOut = DateTime.parse(booking['end_date']);
        totalOccupiedNights += checkOut.difference(checkIn).inDays;
      }

      // Calculate total available nights (365 days)
      const totalAvailableNights = 365;
      
      // Calculate occupancy rate as percentage
      final occupancyRate = (totalOccupiedNights / totalAvailableNights) * 100;
      
      // Cap at 100% and return
      return occupancyRate > 100 ? 100.0 : occupancyRate;
    } catch (e) {
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> _getPopularCities() async {
    try {
      final response = await _supabase
          .from('properties')
          .select('city')
          .eq('is_active', true);

      final Map<String, int> cityCounts = {};

      for (final property in response) {
        final city = property['city'] ?? 'unknown';
        cityCounts[city] = (cityCounts[city] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> popularCities = [];
      cityCounts.forEach((city, count) {
        popularCities.add({
          'city': city,
          'count': count,
        });
      });

      popularCities.sort((a, b) => b['count'].compareTo(a['count']));
      return popularCities.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  // Public method exposed to other layers (e.g., AdminScreen)
  Future<List<Map<String, dynamic>>> getPopularCities() async {
    return _getPopularCities();
  }

  // Track user action
  Future<void> trackUserAction(
      String userId, String action, Map<String, dynamic>? data) async {
    try {
      await _supabase.from('user_actions').insert({
        'user_id': userId,
        'action': action,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      dev.log('Error tracking user action: $e', name: 'AnalyticsService');
    }
  }

  // Track property view
  Future<void> trackPropertyView(String propertyId, String? userId) async {
    try {
      await _supabase.from('property_views').insert({
        'property_id': propertyId,
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      dev.log('Error tracking property view: $e', name: 'AnalyticsService');
    }
  }
}
