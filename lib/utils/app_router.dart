import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:godarna/providers/auth_provider.dart';
import 'package:godarna/constants/app_strings.dart';

import 'package:godarna/screens/splash_screen.dart';
import 'package:godarna/screens/auth/login_screen.dart';
import 'package:godarna/screens/auth/signup_screen.dart';
import 'package:godarna/screens/main/home_screen.dart';
import 'package:godarna/screens/admin/admin_screen.dart';
import 'package:godarna/screens/main/explore_screen.dart';
import 'package:godarna/screens/main/bookings_screen.dart';
import 'package:godarna/screens/notifications/notifications_screen.dart';
import 'package:godarna/screens/payment/payment_screen.dart';
import 'package:godarna/screens/payment/payment_history_screen.dart';
import 'package:godarna/screens/profile/profile_screen.dart';
import 'package:godarna/screens/property/add_property_screen.dart';
import 'package:godarna/screens/property/edit_property_screen.dart';
import 'package:godarna/screens/property/property_details_screen.dart';
import 'package:godarna/screens/chat/chat_screen.dart';
import 'package:godarna/screens/booking/create_booking_screen.dart';
import 'package:godarna/models/property_model.dart';
import 'package:godarna/screens/map/map_screen.dart';
import 'package:godarna/screens/host/host_bookings_screen.dart';
import 'package:godarna/screens/booking/booking_details_screen.dart';

/// Simple ChangeNotifier that listens to a Stream and calls notifyListeners on events
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    // Refresh router when auth state changes
    refreshListenable: _GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (BuildContext context, GoRouterState state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/explore',
        name: 'explore',
        builder: (BuildContext context, GoRouterState state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (BuildContext context, GoRouterState state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (BuildContext context, GoRouterState state) => const MapScreen(),
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (BuildContext context, GoRouterState state) => const BookingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (BuildContext context, GoRouterState state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        name: 'chat',
        builder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['id'];
          final title = state.uri.queryParameters['title'];
          if (id == null || id.isEmpty) {
            return Scaffold(
              body: Center(
                child: Text(AppStrings.getString('notFound', context)),
              ),
            );
          }
          return ChatScreen(chatId: id, title: title);
        },
      ),
      GoRoute(
        path: '/payment',
        name: 'payment',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            final bookingId = extra['bookingId'] as String?;
            final amountRaw = extra['amount'];
            final propertyTitle = extra['propertyTitle'] as String?;
            final amount = amountRaw is num ? amountRaw.toDouble() : 0.0;
            if (bookingId != null && propertyTitle != null) {
              return PaymentScreen(
                bookingId: bookingId,
                amount: amount,
                propertyTitle: propertyTitle,
              );
            }
          }
          return Scaffold(
            body: Center(
              child: Text(AppStrings.getString('paymentParamsMissing', context)),
            ),
          );
        },
      ),
      GoRoute(
        path: '/payment-history',
        name: 'paymentHistory',
        builder: (BuildContext context, GoRouterState state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/property/add',
        name: 'propertyAdd',
        builder: (BuildContext context, GoRouterState state) => const AddPropertyScreen(),
      ),
      GoRoute(
        path: '/property/details',
        name: 'propertyDetails',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra;
          if (extra is PropertyModel) {
            return PropertyDetailsScreen(property: extra);
          }
          return Scaffold(
            body: Center(
              child: Text(AppStrings.getString('propertyNotProvided', context)),
            ),
          );
        },
      ),
      GoRoute(
        path: '/property/:id',
        name: 'propertyById',
        builder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) {
            return Scaffold(
              body: Center(
                child: Text(AppStrings.getString('notFound', context)),
              ),
            );
          }
          return FutureBuilder<PropertyModel?>(
            future: _getPropertyById(id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text('${AppStrings.getString('somethingWentWrong', context)}: ${snapshot.error}'),
                  ),
                );
              }
              final property = snapshot.data;
              if (property == null) {
                return Scaffold(
                  body: Center(
                    child: Text(AppStrings.getString('notFound', context)),
                  ),
                );
              }
              return PropertyDetailsScreen(property: property);
            },
          );
        },
      ),
      GoRoute(
        path: '/property/edit',
        name: 'propertyEdit',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra;
          if (extra is PropertyModel) {
            return EditPropertyScreen(property: extra);
          }
          return Scaffold(
            body: Center(
              child: Text(AppStrings.getString('propertyNotProvided', context)),
            ),
          );
        },
      ),
      GoRoute(
        path: '/booking/create',
        name: 'createBooking',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra;
          if (extra is PropertyModel) {
            return CreateBookingScreen(property: extra);
          }
          return Scaffold(
            body: Center(
              child: Text(AppStrings.getString('propertyNotProvided', context)),
            ),
          );
        },
      ),
      GoRoute(
        path: '/host/bookings',
        name: 'hostBookings',
        builder: (BuildContext context, GoRouterState state) => const HostBookingsScreen(),
      ),
      GoRoute(
        path: '/booking/:id',
        name: 'bookingDetails',
        builder: (BuildContext context, GoRouterState state) {
          final idFromPath = state.pathParameters['id'];
          final extra = state.extra;
          final bookingId = idFromPath ?? (extra is String ? extra : null);
          if (bookingId == null) {
            return Scaffold(
              body: Center(
                child: Text(AppStrings.getString('bookingIdRequired', context)),
              ),
            );
          }
          return BookingDetailsScreen(bookingId: bookingId);
        },
      ),
    ],
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // Use AuthProvider so we can wait for initialization on web refresh
      final auth = context.read<AuthProvider>();
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      final atSplash = state.matchedLocation == '/';
      final exploring = state.matchedLocation == '/explore';

      // While auth not initialized yet, allow splash or auth routes (avoid getting stuck)
      if (!auth.isInitialized) {
        if (loggingIn || atSplash) return null;
        return '/';
      }

      if (!auth.isAuthenticated) {
        // Unauthenticated: send user to login if stuck at splash
        if (atSplash) return '/login';
        // Allow login, signup, explore
        if (loggingIn || exploring) return null;
        return '/login';
      }

      // Authenticated: prevent visiting login/signup/splash
      if (loggingIn || atSplash) {
        return '/home';
      }
      return null;
    },
  );
}

Future<PropertyModel?> _getPropertyById(String id) async {
  try {
    final res = await Supabase.instance.client
        .from('properties')
        .select()
        .eq('id', id)
        .limit(1)
        .maybeSingle();
    if (res == null) return null;
    return PropertyModel.fromJson(res);
  } catch (e) {
    return null;
  }
}
